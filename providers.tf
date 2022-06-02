terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
     },
   backend "s3" {
    bucket = "nginxnetdata"
    key    = "nginx/nginx.tfstate"
    region = "us-east-2"
    profile = "dev"
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
