variable "region" {
  type = string
  description = "Region to use for vpc"
}

variable "aws_profile" {
  type = string
  description = "AWS Profile to use"
}

variable "owner" {
  type = string
  description = "Content for default tag 'owner'"
}

variable "vpc_name" {
  type = string
}

variable "vpc_cidr_block" {
    type = string
}

variable "public_subnet_az" {
  type = string
  default = "eu-west-1b"
}

variable "private_subnet" {
  type = bool
  default = false
  description = "Does this vpc need a private subnet"
}

variable "public_subnet_cidr_block" {
    type = string
}

variable "private_subnet_cidr_block" {
    type = string
    default = null
}