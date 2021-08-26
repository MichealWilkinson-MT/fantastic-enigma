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
  type = string
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

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
}

resource "aws_dynamodb_table" "dynamodb" {
  name     = "fantastic-enigma-shas"
  hash_key = "InputString"
  write_capacity = 2
  read_capacity = 2
  attribute {
    name = "InputString"
    type = "S"
  }
}

data "aws_iam_policy_document" "role_access_database_policy_doc" {
  statement {
    sid       = "DatabaseAccess"
    actions   = ["dynamodb:PutItem"] //sqs.delete sqs/recieve sqs.getQAttr
    effect    = "Allow"
    resources = [ aws_dynamodb_table.dynamodb.arn ]
  }
}

// new policy for SQS 
data "aws_iam_policy_document" "sqs_trigger_lambda" {
  statement {
    actions = ["lambda:CreateEventSourceMapping","lambda:ListEventSourceMappings","lambda:ListFunctions"]
    effect  = "Allow"
    resources = [ aws_lambda_function.dynamodb-writer.arn ]
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "role_access_database_policy" {
  name   = "MedichecksDatabaseWriteLambdaPolicy"
  policy = data.aws_iam_policy_document.role_access_database_policy_doc.json
}

resource "aws_iam_policy" "sqs_trigger_lambda" {
  name  = "sqs-lambda-trigger"
  policy = data.aws_iam_policy_document.sqs_trigger_lambda.json
}

// CReate a role form the policy

resource "aws_iam_role" "role_access_database_role" { //That's how I roll
  name = "DatabaseWriter"
  managed_policy_arns = [
    aws_iam_policy.role_access_database_policy.arn
  ]
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_sqs_queue" "import-queue" {
  name                        = "medichecks-import-q.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

resource "aws_lambda_function" "dynamodb-writer" {
  s3_key          = "s3://meditest-tf-state/function.zip"
  function_name   = "dynamodb-writer"
  role            = aws_iam_role.sqs_trigger_lambda.arn
  handler         = "bin/dynamodb-writer"
  runtime         = "go1.x"
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
  value       = aws_iam_role.role_access_database_role.arn
}