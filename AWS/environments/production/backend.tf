terraform {
  backend "s3" {
    # 使用方法: terraform init -backend-config="bucket=terraform-state-ACCOUNT_ID-ap-northeast-1"
    # または、このファイルのbucketを実際のバケット名に置き換えてください
    key            = "production/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
