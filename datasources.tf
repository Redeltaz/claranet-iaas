data "aws_ami" "support_asg_launch_ami" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-11-amd64-*"]
  }
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