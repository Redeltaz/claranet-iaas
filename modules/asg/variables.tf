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
  type = string
  description = "Key pair to use for ssh connection to bastion"
}

variable "iam_bastion_profil_name" {
  type = string
  description = "IAM profile to use for the bastion"
}

variable "subnet_id" {
  type = string
  description = "ID of the subnet where the instances are launched"
}

variable "sg_id" {
  type = string
  description = "Security Group to attach to the instances"
}

variable "subnet_az" {
  type = string
}