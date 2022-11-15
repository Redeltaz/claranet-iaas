data "aws_ami" "asg_launch_base_ami" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-11-amd64-*"]
  }
}

data "aws_ami" "asg_launch_custom_ami" {
  most_recent = true
  owners      = ["609291635675"]

  filter {
    name   = "name"
    values = ["lc-iaas-ami-*"]
  }
}

 data "template_file" "user_data_template" {
   template = <<eof
    apt update
    apt install ruby-full
    apt install wget
    wget https://aws-codedeploy-eu-west-1.s3.eu-west-1.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
   eof
   #template = <<eof
     ##!/bin/bash
     #set -xe

     #echo "attach eip to this instance" 
     #aws_instance_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)
     #aws_az=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
     #aws_region=$(echo $aws_az | sed 's/.$//')
     #aws ec2 associate-address --region $aws_region --instance-id $aws_instance_id --allocation-id ${aws_eip.bastion_eip.id} --allow-reassociation
     #echo 'eip was successfully attached to the instance'
   #eof
 }
