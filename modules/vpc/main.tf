resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.vpc_name} VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  count      = 1
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidr_block

  tags = {
    Name = "${var.vpc_name} public subnet"
  }
}

resource "aws_internet_gateway" "vpc_ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name} VPC internet gateway"
  }
}

resource "aws_route_table" "vpc_route_table" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.vpc_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_ig.id
}

resource "aws_main_route_table_association" "main_route_association" {
  vpc_id         = aws_vpc.support_vpc.id
  route_table_id = aws_route_table.support_vpc_route_table.id
}

resource "aws_security_group" "public_sg" {
  name        = "public_sg"
  vpc_id      = aws_vpc.vpc.id

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

resource "aws_launch_template" "public_asg_launch_template" {
  name          = "${var.vpc_name}_VPC_ASG_launch_template"
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

resource "aws_autoscaling_group" "public_asg" {
  name               = "${var.vpc_name}_VPC_ASG"
  availability_zones = [var.public_subnet_az]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.public_asg_launch_template.id
    version = "$Latest"
  }
}

resource "aws_route53_zone" "private_dns_zone" {
  name = "${var.vpc_name}-vpc-lucas.com"

  vpc {
    vpc_id = aws_vpc.vpc.id
  }
}