resource "aws_launch_template" "asg_launch_template" {
  count = var.create ? 1 : 0

  name          = "${var.vpc_name}-vpc-${var.name}-launch-template"
  image_id      = data.aws_ami.asg_launch_ami.id
  instance_type = "t3.micro"
  key_name      = var.key_pair_name

  iam_instance_profile {
    name = var.iam_profil_name
  }

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = var.subnet_id
    security_groups             = [var.sg_id]
  }

  instance_market_options {
    market_type = "spot"
  }

  # TODO Error with aws cli command that didn't change the EIP
  #user_data = base64encode(data.template_file.user_data_template.rendered)
}

resource "aws_autoscaling_group" "asg" {
  count = var.create ? 1 : 0

  name               = "${var.vpc_name}-vpc-${var.name}-asg"
  availability_zones = [var.subnet_az]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.asg_launch_template[0].id
    version = "$Latest"
  }
}