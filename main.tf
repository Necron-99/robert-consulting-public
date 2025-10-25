terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17"
    }
  }
  
  backend "s3" {
    bucket  = "robert-consulting-terraform-test-1761410906"
    key     = "test.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# Simple test resource
resource "aws_s3_bucket" "test" {
  bucket = "test-new-bucket-${random_id.test.hex}"
  
  tags = {
    Name = "Test New Bucket"
  }
}

resource "random_id" "test" {
  byte_length = 4
}
