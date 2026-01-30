
# Provider & Variables
provider "aws" {

  region = var.aws_region

}



variable "aws_region" {}

variable "vpc_cidr" {}

variable "public_subnet_cidr" {}

variable "instance_type" {}

variable "ami_id" {}

variable "key_name" {}

variable "http_ingress_cidrs" {

  type = list(string)

}

variable "ssh_ingress_cidrs" {

  type = list(string)

}


# VPC

resource "aws_vpc" "main_vpc" {

  cidr_block           = var.vpc_cidr

  enable_dns_support   = true

  enable_dns_hostnames = true



  tags = {

    Name = "capstone1-vpc"

  }

}



# Public Subnet

resource "aws_subnet" "public_subnet" {

  vpc_id                  = aws_vpc.main_vpc.id

  cidr_block              = var.public_subnet_cidr

  map_public_ip_on_launch = true



  tags = {

    Name = "capstone1-public-subnet"

  }

}



# Internet Gateway

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main_vpc.id



  tags = {

    Name = "capstone1-igw"

  }

}



# Route Table (public)

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.main_vpc.id



  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id

  }



  tags = {

    Name = "capstone1-public-rt"

  }

}



# RT Association

resource "aws_route_table_association" "rt_assoc" {

  subnet_id      = aws_subnet.public_subnet.id

  route_table_id = aws_route_table.public_rt.id

}


# Security Group

resource "aws_security_group" "web_sg" {

  name        = "web-sg"

  description = "Allow HTTP & SSH"

  vpc_id      = aws_vpc.main_vpc.id



  # HTTP

  ingress {

    from_port   = 80

    to_port     = 80

    protocol    = "tcp"

    cidr_blocks = var.http_ingress_cidrs

  }



  # SSH

  ingress {

    from_port   = 22

    to_port     = 22

    protocol    = "tcp"

    cidr_blocks = var.ssh_ingress_cidrs

  }



  # Egress - all

  egress {

    from_port   = 0

    to_port     = 0

    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }



  tags = {

    Name = "capstone1-web-sg"

  }

}


# EC2 Instance (Amazon Linux 2023)


resource "aws_instance" "web" {

  ami                         = var.ami_id

  instance_type               = var.instance_type

  subnet_id                   = aws_subnet.public_subnet.id

  associate_public_ip_address = true

  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  key_name                    = var.key_name

  user_data = <<-EOF

   #!/bin/bash

   set -euxo pipefail

   sudo  dnf update -y

   sudo  dnf install -y httpd

   sudo  systemctl enable httpd

   sudo  systemctl start httpd


  cat > /var/www/html/index.html <<'HTML'

  <h1>Hello from Terraform Capstone1 EC2 (Amazon Linux 2023)!</h1>

   HTML

   EOF	

  tags = {

    Name = "Ojas_Ec2"

  }

}



output "public_ip" {

  value = aws_instance.web.public_ip

  description = "Public IP of the web server"

}
