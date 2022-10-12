locals {
  aws_region = "eu-west-1"
  aws_profile = "claranet-sandbox-bu-spp"
  aws_owner = "lucas.campistron@fr.clara.net"
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
    command = "echo '${tls_private_key.key_generated.private_key_pem}' > ./public-key.pem"
  }
}

module "support_vpc" {
  source = "./modules/vpc"

  vpc_name = "support"
  vpc_cidr_block = "10.0.0.0/16"
  public_subnet_az = "eu-west-1b"
  private_subnet = false
  public_subnet_cidr_block = "10.0.1.0/24"
  key_pair_name = aws_key_pair.main_key_pair.key_name
  create_eip = true
}