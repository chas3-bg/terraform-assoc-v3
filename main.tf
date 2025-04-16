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
  load_balancers = aws_elb.terraform-v3-elb.name
  health_check_type = "ELB"

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

resource "aws_security_group" "elb-sg" {
  name = "elb-terraform-v3-sg"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress  {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

resource "aws_elb" "terraform-v3-elb" {
  name = "elb-terraform-v3"
  availability_zones = [data.aws_availability_zones.all.names]
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = var.app_port
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.app_port}/"
  }
  
}
output "elb-pub-dns" {
  value = aws_elb.terraform-v3-elb.dns_name
}