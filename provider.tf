provider "aws" {
  region  = "eu-west-1"
  profile = "claranet-sandbox-bu-spp"

  default_tags {
    tags = {
      owner = "lucas.campistron@fr.clara.net"
    }
  }
}