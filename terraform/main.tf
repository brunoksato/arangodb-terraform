provider "aws" {
  region  = "us-east-1"
  version = "~> 2.0"
}

terraform {
  backend "s3" {
    bucket = "gruff-tfstates-terraform"
    key    = "terraform-gruff.tfstate"
    region = "us-east-1"
  }
}

