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
  availability_zone = var.public_subnet_az

  tags = {
    Name = "${var.vpc_name} public subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  count = var.private_subnet ? 1 : 0

  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet_cidr_block
  availability_zone = var.public_subnet_az

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
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.vpc_route_table.id
}

resource "aws_security_group" "main_sg" {
  name        = "main_sg"
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


# resource "aws_eip" "bastion_eip" {
#   count = var.create_eip ? 1 : 0
#   vpc = true
# }

resource "aws_route53_zone" "private_dns_zone" {
  name = "${var.vpc_name}-vpc-lucas.com"

  vpc {
    vpc_id = aws_vpc.vpc.id
  }
}

module "public_asg" {
  source = "../asg"

  name = "public"
  create = true
  vpc_name = var.vpc_name
  key_pair_name = var.key_pair_name
  iam_bastion_profil_name = aws_iam_instance_profile.iam_bastion_profil.name
  subnet_id = aws_subnet.public_subnet[0].id
  sg_id = aws_security_group.main_sg.id
  subnet_az = var.public_subnet_az
}


module "private_asg" {
  source = "../asg"

  name = "private"
  create = var.private_subnet ? true : false
  vpc_name = var.vpc_name
  key_pair_name = var.key_pair_name
  iam_bastion_profil_name = aws_iam_instance_profile.iam_bastion_profil.name
  subnet_id = var.private_subnet ? aws_subnet.private_subnet[0].id : null
  sg_id = aws_security_group.main_sg.id
  subnet_az = var.public_subnet_az
}