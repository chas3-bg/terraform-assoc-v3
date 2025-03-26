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
  availability_zone = "eu-west-1a"

  tags = {
    Name = "Test server"
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = "eu-west-1a"
  size              = 1
  encrypted         = true
  type              = "gp3"
}

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.test_server.id
}
