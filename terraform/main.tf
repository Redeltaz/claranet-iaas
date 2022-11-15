locals {
  aws_region  = "eu-west-1"
  aws_profile = "claranet-sandbox-bu-spp"
  aws_owner   = "lucas.campistron@fr.clara.net"
}

provider "aws" {
  region  = local.aws_region
  profile = local.aws_profile

  default_tags {
    tags = {
      owner = local.aws_owner
    }
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
    command = "echo '${tls_private_key.key_generated.private_key_pem}' > ./private-key.pem"
  }
}

resource "aws_iam_policy" "main_policy" {
  name = "main-policy"

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

resource "aws_iam_role" "main_role" {
  name = "main-role"

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

resource "aws_iam_policy_attachment" "attach_main_iam_policy" {
  name       = "attach_ain_iam_Policy"
  roles      = [aws_iam_role.main_role.name]
  policy_arn = aws_iam_policy.main_policy.arn
}

resource "aws_iam_instance_profile" "iam_main_profil" {
  name = "lucas_main_iam_profil"
  role = aws_iam_role.main_role.name
}

module "support_vpc" {
  source = "./modules/vpc"

  vpc_name                 = "support"
  vpc_cidr_block           = "172.31.0.0/16"
  peered_vpc_cidr_block    = "10.1.0.0/16"
  subnet_az                = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnet           = false
  public_subnet_cidr_block = ["172.31.1.0/24", "172.31.2.0/24", "172.31.3.0/24"]
  key_pair_name            = aws_key_pair.main_key_pair.key_name
  iam_profil_name          = aws_iam_instance_profile.iam_main_profil.name
  vpc_peering_id           = aws_vpc_peering_connection.support_preprod_vpc_peering.id
  create_eip               = true
}

module "preprod_vpc" {
  source = "./modules/vpc"

  vpc_name                  = "preprod"
  vpc_cidr_block            = "10.1.0.0/16"
  peered_vpc_cidr_block     = "172.31.0.0/16"
  subnet_az                 = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnet            = true
  public_subnet_cidr_block  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  private_subnet_cidr_block = "10.1.4.0/24"
  key_pair_name             = aws_key_pair.main_key_pair.key_name
  iam_profil_name           = aws_iam_instance_profile.iam_main_profil.name
  vpc_peering_id            = aws_vpc_peering_connection.support_preprod_vpc_peering.id
}

resource "aws_vpc_peering_connection" "support_preprod_vpc_peering" {
  peer_vpc_id = module.support_vpc.vpc_id
  vpc_id      = module.preprod_vpc.vpc_id
  auto_accept = true
}

resource "aws_lb" "main_alb" {
    name                       = "preprod-alb"
    internal                   = false
    load_balancer_type         = "application"
    subnets = module.preprod_vpc.public_subnet_ids

    tags = {
        Name = "preprod-alb"
    }
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "lucas-app-bucket"

  tags = {
    Name        = "lucas-iaas-app-bucket"
  }
}

resource "aws_db_instance" "app_rds" {
  allocated_storage    = 10
  db_name              = "lucas_iaas_rds"
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  username             = "lucas"
  password             = "password"
}

resource "aws_route53_record" "rds_record" {
  zone_id = module.preprod_vpc.dns_id
  name    = "www.lucas-iaas-rds.com"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.app_rds.address]
}

resource "aws_elasticache_cluster" "app_elasticache" {
  cluster_id           = "cluster-iaas-lucas"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  port                 = 6379
}

#resource "aws_route53_record" "elasticache_record" {
  #zone_id = module.preprod_vpc.dns_id
  #name    = "www.lucas-iaas-elasticache.com"
  #type    = "CNAME"
  #ttl     = 300
  #records = [aws_elasticache_cluster.app_elasticache.cluster_address]
#}
