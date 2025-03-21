terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.89.0"
    }
  }

  backend "s3" {
    bucket = "terraformstateshyam7rc"
    key    = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "Terraform"
  }


}
