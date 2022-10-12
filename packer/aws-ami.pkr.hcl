packer {
  required_plugins {
    amazon = {
      version = "= 1.1.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  profile = "claranet-sandbox-bu-spp"
  ami_name = "aws-custom-debian-ami"
  instance_type = "t3.micro"
  ami_region = "eu-west-1"
  region = "eu-west-1"
}

source "amazon-ebs" "aws_custom_debian_ami" {
  ami_name = local.ami_name
  ami_regions = [local.ami_region]
  instance_type = local.instance_type
  region        = local.region
  ssh_username = "admin"

  source_ami_filter {
    filters = {
      name = "debian-11-amd64-*"
    }
    most_recent = true
    owners      = ["136693071363"]
  }

  tags = {
    Name = local.ami_name
    created_by = "packer"
    owner = "lucas.campistron@fr.clara.net"
  }
}

build {
  sources = ["source.amazon-ebs.aws_custom_debian_ami"]
  name = "aws-custom_debian-ami-build"

  provisioner "shell" {
    inline = ["mkdir /home/admin/test"]
  }
}