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
    actions   = ["dynamodb:PutItem"]
    effect    = "Allow"
    resources = [aws_dynamodb_table.dynamodb.arn]
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

resource "aws_iam_role" "role_access_database_role" { //That's how I roll
  name = "DatabaseWriter"
  managed_policy_arns = [
    aws_iam_policy.role_access_database_policy.arn
  ]
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}