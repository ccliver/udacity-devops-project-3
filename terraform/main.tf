provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.48.0"

  name = "udacity-devops-project-3"

  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a"]
  private_subnets = []
  public_subnets  = ["10.0.101.0/24"]

  enable_ipv6 = true

  enable_nat_gateway = false
  single_nat_gateway = true

  public_subnet_tags = {
    Name = var.project_name
  }

  tags = {
    Name = var.project_name
  }

  vpc_tags = {
    Name = var.project_name
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "aws_key_pair" "jenkins" {
  key_name   = "jenkins"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "ssh_key" {
  sensitive_content = tls_private_key.ssh_key.private_key_pem
  filename          = "${path.module}/id_rsa"
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

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "jenkins" {
  name   = "${var.project_name}-jenkins"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.project_name
  }
}

resource "aws_iam_instance_profile" "jenkins" {
  name = var.project_name
  role = aws_iam_role.jenkins.name
}

resource "aws_iam_role" "jenkins" {
  name = var.project_name
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "jenkins" {
  name = var.project_name
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "001",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "${aws_s3_bucket.app.arn}",
        "${aws_s3_bucket.app.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  key_name                    = aws_key_pair.jenkins.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  associate_public_ip_address = true
  user_data                   = <<-USERDATA
    #!/bin/bash
    apt-get update
    apt install -y default-jdk
    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
    echo 'deb https://pkg.jenkins.io/debian-stable binary/' > /etc/apt/sources.list.d/jenkins.list
    apt-get update
    apt-get install -y jenkins tidy
    systemctl start jenkins
    systemctl enable jenkins
    systemctl status jenkins
  USERDATA

  tags = {
    Name = "${var.project_name}-jenkins"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "aws_s3_bucket" "app" {
    bucket = "${var.project_name}-app"
    acl    = "private"
}
