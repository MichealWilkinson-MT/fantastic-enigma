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
    key = "meditest.tfstate"
    region = "eu-west-2"
  }
}
provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    CreatedBy = "Micheal Wilkinson"
  }
}

resource "aws_subnet" "meditest-sub-1" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "eu-west-2a"
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, 1)
  tags = {
      Name = "meditest-sub-1"
    CreatedBy =  "Micheal Wilkinson"
  }
}

resource "aws_network_interface" "meditest-ni-1" {
  subnet_id = aws_subnet.meditest-sub-1.id
  tags = {
      Name = "meditest-net-1"
    CreatedBy =  "Micheal Wilkinson"
  }
}

resource "aws_instance" "test_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  network_interface {
    network_interface_id = aws_network_interface.meditest-ni-1.id
    device_index         = 0
  }
  tags = {
    Name = "meditest-server"
    CreatedBy =  "Micheal Wilkinson"
  }
}