terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
     }
  }
}

provider "aws" {
  region = var.reg
  alias   = "dev"
  profile = "dev"
}

provider "aws" {
  region  = var.reg
  alias   = "prod"
  profile = "prod"
}
