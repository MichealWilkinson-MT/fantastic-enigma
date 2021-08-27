terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.55"
    }
  }
  backend "s3" {
    bucket = "meditest-tf-state"
    key    = "meditest.tfstate"
    region = "eu-west-2"
  }
}

variable "stage" {
  type    = string
  default = "dev"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-2"
  default_tags {
    tags = {
      CreatedBy = "MedichecksTeam"
    }
  }
}

data "aws_caller_identity" "aws_acc" {}
data "aws_region" "aws_region" {}

resource "aws_dynamodb_table" "dynamodb" {
  name           = "fantastic-enigma-shas"
  hash_key       = "InputString"
  write_capacity = 2
  read_capacity  = 2
  attribute {
    name = "InputString"
    type = "S"
  }
}

data "aws_iam_policy_document" "hash_function_policy_doc" {
  statement {
    sid = "DatabaseAccess"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem"
    ]
    effect    = "Allow"
    resources = [aws_dynamodb_table.dynamodb.arn]
  }

  statement {
    sid = "ConsumeQueue"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
    effect    = "Allow"
    resources = [
      "arn:aws:sqs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_acc.account_id}:*"
    ]
  } 

  statement {
    sid = "WriteLogs"
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

data "aws_iam_policy_document" "sqs_trigger_lambda" {
  statement {
    actions   = ["lambda:CreateEventSourceMapping", "lambda:ListEventSourceMappings", "lambda:ListFunctions"]
    effect    = "Allow"
    resources = ["arn:aws:lambda:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_acc.account_id}:function:*"]
  }
}

data "aws_iam_policy_document" "dynamodbwriter_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "importsqs_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "sqs.amazonaws.com"
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "hash_function_policy" {
  name   = "MedichecksDatabaseWriteLambdaPolicy"
  policy = data.aws_iam_policy_document.hash_function_policy_doc.json
}

resource "aws_iam_role" "hash_function_role" {
  name = "DatabaseWriter"
  managed_policy_arns = [
    aws_iam_policy.hash_function_policy.arn
  ]
  assume_role_policy = data.aws_iam_policy_document.dynamodbwriter_assume_role_policy.json
}

resource "aws_sqs_queue" "import-queue" {
  name                        = "medichecks-import-q.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  policy = data.aws_iam_policy_document.sqs_trigger_lambda.json
}

resource "aws_ssm_parameter" "import-queue-arn" {
  name        = "/fantastic-enigma/${var.stage}/inputQueue/arn"
  description = "arn for the import queue in the ${var.stage} environment"
  type        = "SecureString"
  value       = aws_sqs_queue.import-queue.arn
}

resource "aws_ssm_parameter" "import-lambda-role-arn" {
  name        = "/fantastic-enigma/${var.stage}/lambda/role-arn"
  description = "arn for the lambda role in the ${var.stage} environment"
  type        = "SecureString"
  value       = aws_iam_role.hash_function_role.arn
}