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

data "aws_availability_zones" "all" {}

variable "app_port" {
  default = 8080
  
}

variable "allow_all" {
  default = "0.0.0.0/0"
  
}
resource "aws_launch_configuration" "test_server" {
  image_id           = data.aws_ami.fedora41.id
  instance_type = "t2.micro"
  security_groups = ["aws_security_group.defaultsg.id"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello from terraformed server" > index.html
              nohup busybox httpd -f -p "${var.app_port}"
              EOF
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "app_servers" {
  launch_configuration = aws_launch_configuration.test_server.id
  min_size = 2
  max_size = 10
  availability_zones = data.aws_availability_zones.all.names

  tag {
    key = "name"
    value = "terraform v3"
    propagate_at_launch = true
  }
  
}
resource "aws_security_group" "defaultsg" {
  name        = "defaultsg"

  ingress {
    description = "TLS from VPC"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = var.allow_all
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allow_all]
  }

}

#TODO: LB
