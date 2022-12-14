variable "vpc_name" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "peered_vpc_cidr_block" {
  type = string
}

variable "private_subnet" {
  type        = bool
  default     = false
  description = "Does this vpc need a private subnet"
}

variable "subnet_az" {
  type = list(any)
}

variable "public_subnet_cidr_block" {
  type = list(any)
}

variable "private_subnet_cidr_block" {
  type    = string
  default = null
}

variable "key_pair_name" {
  type        = string
  description = "Key pair to use for ssh connection to bastion"
}

variable "create_eip" {
  type    = bool
  default = false
}

variable "iam_profil_name" {
  type = string
}

variable "vpc_peering_id" {
  type = string
}