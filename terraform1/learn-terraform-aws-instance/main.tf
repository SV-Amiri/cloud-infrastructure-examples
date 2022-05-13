terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  #region  = "ap-southeast-2"
  region = "us-east-2"
}

resource "aws_instance" "app_server" {
  # ami           = "ami-4e101b2d"
  ami = "ami-0773fc21d80336e3e"
  #  instance_type = "t2.large"
  instance_type = "t4g.micro"

  tags = {
    Name        = "ExampleAppServerInstance"
    Environment = "production"
  }
}



