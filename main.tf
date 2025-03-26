terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  #required version of Terraform
  required_version = ">=1.11.0"
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_ami" "fedora41" {
  most_recent = true
  owners      = ["125523088429"]
  filter {
    name   = "name"
    values = ["Fedora-Cloud-Base-AmazonEC2.x86_64-41-*"]
  }
}

resource "aws_instance" "test_server" {
  ami           = data.aws_ami.fedora41.id
  instance_type = "t2.micro"

  tags = {
    Name = "Test server"
  }
}