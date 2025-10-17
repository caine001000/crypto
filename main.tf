terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Provider for Singapore region
provider "aws" {
  alias  = "singapore"
  region = "ap-southeast-1"
}

# Provider for Tokyo region
provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}

# Default provider (Singapore)
provider "aws" {
  region = "ap-southeast-1"
}