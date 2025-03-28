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
  region = "eu-central-1"
}

variable "port" {
  description = "Port for the application"
  type = number
  default = 8080
  
}


output "PublicIP" {
  value = aws_instance.test_server.public_ip 
}

output "PublicDNS" {
  value = aws_instance.test_server.public_dns
  
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
  ami               = data.aws_ami.fedora41.id
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1a"
  vpc_security_group_ids = ["aws_security_group.defaultsg.id"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello from terraformed server" > index.html
              nohup busibox httpd -f -p "${var.port}" &
              EOF

  tags = {
    Name = "Test server"
  }
}

resource "aws_security_group" "defaultsg" {
  name        = "defaultSG"
  description = "Allow 8080/tcp"


  ingress {
    description = "TLS from VPC"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}



resource "aws_ebs_volume" "data" {
  availability_zone = "eu-central-1a"
  size              = 1
  encrypted         = true
  type              = "gp3"
}

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.test_server.id
}
