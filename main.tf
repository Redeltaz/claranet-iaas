terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_vpc" "support_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Support VPC"
  }
}

resource "aws_subnet" "support_public_subnets" {
  count      = 1
  vpc_id     = aws_vpc.support_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Support public subnet"
  }
}

resource "aws_internet_gateway" "support_vpc_ig" {
  vpc_id = aws_vpc.support_vpc.id

  tags = {
    Name = "Support VPC internet gateway"
  }
}

resource "aws_route53_zone" "support_private_dns_zone" {
  name = "support-vpc-lucas-campistron.com"

  vpc {
    vpc_id = aws_vpc.support_vpc.id
  }
}

resource "aws_launch_template" "support_launch_template" {
  image_id      = data.aws_ami.support_asg_launch_ami.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.main

  instance_market_options {
    market_type = "spot"
  }
}

resource "aws_key_pair" "main" {
  key_name   = "main_key_pair"
  public_key = var.public_secret_key
}

resource "aws_autoscaling_group" "support_asg" {
  availability_zones = ["eu-west-1"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.support_launch_template.id
    version = "$Latest"
  }
}