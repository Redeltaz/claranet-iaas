terraform {
  required_providers {
    aws = {
      version = "4.34.0"
      source  = "hashicorp/aws"
    }
  }
}

resource "aws_vpc" "support_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Support VPC"
  }
}


resource "aws_subnet" "support_public_subnet" {
  count             = 1
  vpc_id            = aws_vpc.support_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1b"

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
resource "aws_route_table" "support_vpc_route_table" {
  vpc_id = aws_vpc.support_vpc.id
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.support_vpc_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.support_vpc_ig.id
}

resource "aws_main_route_table_association" "main_route_association" {
  vpc_id         = aws_vpc.support_vpc.id
  route_table_id = aws_route_table.support_vpc_route_table.id
}

resource "aws_route53_zone" "support_private_dns_zone" {
  name = "support-vpc-lucas-campistron.claranet"

  vpc {
    vpc_id = aws_vpc.support_vpc.id
  }
}

resource "tls_private_key" "key_generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main_key_pair" {
  key_name   = "lucas_iaas_key_pair"
  public_key = tls_private_key.key_generated.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.key_generated.private_key_pem}' > ./public-key.pem"
  }
}

resource "aws_eip" "support_eip" {
  vpc = true
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.support_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_policy" "bastion_policy" {
  name = "Bastion_Policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "*"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "bastion_role" {
  name = "bastion_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "attach_bastion_iam_policy" {
  name       = "Attach_Bastion_IAM_Policy"
  roles      = [aws_iam_role.bastion_role.name]
  policy_arn = aws_iam_policy.bastion_policy.arn
}

resource "aws_iam_instance_profile" "iam_bastion_profil" {
  name = "Bastion_IAM_profil"
  role = aws_iam_role.bastion_role.name
}

data "template_file" "user_data_template" {
  template = <<EOF
    #!/bin/bash
    set -xe

    echo "Attach EIP to this instance" 
    AWS_INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
    AWS_AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    AWS_REGION=$(echo $AWS_AZ | sed 's/.$//')
    aws ec2 associate-address --region $AWS_REGION --instance-id $AWS_INSTANCE_ID --allocation-id ${aws_eip.support_eip.id} --allow-reassociation
    echo 'EIP was successfully attached to the instance'
  EOF
}

resource "aws_launch_template" "support_launch_template" {
  name          = "Support_VPC_ASG_launch_template"
  image_id      = data.aws_ami.support_asg_launch_ami.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.main_key_pair.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.iam_bastion_profil.name
  }

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.support_public_subnet[0].id
    security_groups             = [aws_security_group.allow_ssh.id]
  }

  instance_market_options {
    market_type = "spot"
  }

  user_data = base64encode(data.template_file.user_data_template.rendered)
}

resource "aws_autoscaling_group" "support_asg" {
  name               = "Support VPC ASG"
  availability_zones = ["eu-west-1b"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.support_launch_template.id
    version = "$Latest"
  }
}
