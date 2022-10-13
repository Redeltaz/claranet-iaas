variable "create" {
  type = bool
}

variable "name" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "key_pair_name" {
  type        = string
  description = "Key pair to use for ssh connection to bastion"
}

variable "iam_profil_name" {
  type        = string
  description = "IAM profile to attach"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet where the instances are launched"
}

variable "sg_id" {
  type        = string
  description = "Security Group to attach to the instances"
}

variable "subnet_az" {
  type = string
}

variable "custom_ami" {
  type        = bool
  description = "Does the asg use the default or custom ami ?"
}