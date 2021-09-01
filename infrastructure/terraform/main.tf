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