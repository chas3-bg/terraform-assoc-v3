
terraform {
  cloud {
    organization = "terraform-v3-exam"
    workspaces {
      name = "master"
    }
  }
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

resource "aws_instance" "srv2" {
    ami = data.aws_ami.fedora41.id
    instance_type = "t2.micro"
    security_groups = [aws_security_group.defaultsg.id]

  
}

resource "aws_security_group" "defaultsg" {
  name        = "defaultsg"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}