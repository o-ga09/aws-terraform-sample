terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"

  # Bootstrap環境ではローカルstateを使用
  # 実行後、バックエンドをS3に移行
}

provider "aws" {
  region = var.aws_region
}
