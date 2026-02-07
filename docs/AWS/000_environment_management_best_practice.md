# Terraform 環境別管理のベストプラクティス

複数環境（Prod、Stg、Dev）を管理する際の主要なアプローチとそれぞれの特徴を解説します。

## 主要なアプローチ比較

### 1. Workspace方式 ⭐ シンプル
**メリット:**
- コードの重複が少ない
- 切り替えが簡単（`terraform workspace select`）
- 小規模プロジェクト向き

**デメリット:**
- 同じバックエンドを共有（誤操作リスク）
- 環境間の差分が大きいと管理が複雑
- ステート分離が弱い

**推奨ケース:** 環境間の差がほぼ変数のみの場合

---

### 2. ディレクトリ分離方式 ⭐⭐⭐ 推奨
**メリット:**
- 環境ごとに完全に独立
- ステート分離で誤操作防止
- 環境固有の設定が管理しやすい
- CI/CDとの統合が容易

**デメリット:**
- コードの重複が発生しやすい
- メンテナンスコストが高い

**推奨ケース:** 中〜大規模プロジェクト、本番環境がある場合

---

### 3. Terragrunt方式 ⭐⭐⭐⭐ エンタープライズ向け
**メリット:**
- DRY原則を維持
- 依存関係の管理が容易
- 大規模プロジェクト向き

**デメリット:**
- 学習コスト
- ツールの追加が必要

**推奨ケース:** 複雑な依存関係、多数の環境がある場合

---

### 4. Terraform Modules + 環境別設定 ⭐⭐⭐⭐⭐ ベストプラクティス
**メリット:**
- コードの再利用性が高い
- 環境ごとの柔軟性
- テスト可能
- スケーラブル

**デメリット:**
- 初期設計コスト
- モジュール設計スキルが必要

**推奨ケース:** ほとんどのプロダクション環境

---

## 推奨構成: Modules + ディレクトリ分離

以下の構成を推奨します：

```
terraform/
├── modules/                    # 再利用可能なモジュール
│   ├── vpc/
│   ├── ecs/
│   ├── rds/
│   └── alb/
├── environments/               # 環境ごとの設定
│   ├── prod/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── stg/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── backend.tf
└── README.md
```

## 重要な原則

### 1. ステート完全分離
```hcl
# prod/backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# stg/backend.tf
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "stg/terraform.tfstate"  # 異なるキー
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

### 2. 変数による環境差分の吸収
```hcl
# prod/terraform.tfvars
environment         = "prod"
instance_type       = "t3.large"
min_capacity        = 2
max_capacity        = 10
enable_deletion_protection = true
backup_retention_period    = 30
multi_az            = true

# dev/terraform.tfvars
environment         = "dev"
instance_type       = "t3.small"
min_capacity        = 1
max_capacity        = 2
enable_deletion_protection = false
backup_retention_period    = 7
multi_az            = false
```

### 3. タグ付け戦略
```hcl
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    CostCenter  = var.cost_center
    Owner       = var.owner
  }
}

resource "aws_instance" "example" {
  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-web-server"
    }
  )
}
```

### 4. 命名規則の統一
```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  
  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}
```

### 5. 環境固有リソースの条件分岐
```hcl
# 本番のみでバックアップ有効化
resource "aws_db_instance" "main" {
  backup_retention_period = var.environment == "prod" ? 30 : 7
  multi_az                = var.environment == "prod" ? true : false
  deletion_protection     = var.environment == "prod" ? true : false
}

# 本番のみでWAF有効化
resource "aws_wafv2_web_acl_association" "main" {
  count        = var.environment == "prod" ? 1 : 0
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main[0].arn
}
```

## セキュリティベストプラクティス

### 1. 環境別IAMロール
```hcl
# 本番環境は承認者のみがデプロイ可能
data "aws_iam_policy_document" "github_actions" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    principals {
      type        = "Federated"
      identifiers = [var.github_oidc_provider_arn]
    }
    
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      # 本番は main ブランチのみ、開発は全て許可
      values   = var.environment == "prod" ? [
        "repo:org/repo:ref:refs/heads/main"
      ] : [
        "repo:org/repo:*"
      ]
    }
  }
}
```

### 2. 機密情報の管理
```hcl
# 絶対に tfvars にパスワードを書かない
# Secrets Manager または SSM Parameter Store を使用

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "${var.environment}/rds/master-password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

### 3. State の暗号化とロック
```hcl
# S3バケットの暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# バージョニング有効化
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
```

## CI/CD統合

### GitHub Actions 例
```yaml
name: Terraform

on:
  push:
    branches:
      - main
      - develop
    paths:
      - 'terraform/**'

env:
  TF_VERSION: 1.6.0

jobs:
  terraform:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, stg, prod]
        include:
          - environment: dev
            branch: develop
            auto_approve: true
          - environment: stg
            branch: develop
            auto_approve: false
          - environment: prod
            branch: main
            auto_approve: false
    
    # ブランチと環境のマッチング
    if: |
      (matrix.environment == 'dev' && github.ref == 'refs/heads/develop') ||
      (matrix.environment == 'stg' && github.ref == 'refs/heads/develop') ||
      (matrix.environment == 'prod' && github.ref == 'refs/heads/main')
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets[format('AWS_ROLE_{0}', matrix.environment)] }}
          aws-region: ap-northeast-1
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Init
        working-directory: terraform/environments/${{ matrix.environment }}
        run: terraform init
      
      - name: Terraform Plan
        working-directory: terraform/environments/${{ matrix.environment }}
        run: terraform plan -out=tfplan
      
      - name: Terraform Apply
        if: matrix.auto_approve || github.event_name == 'workflow_dispatch'
        working-directory: terraform/environments/${{ matrix.environment }}
        run: terraform apply tfplan
```

## よくあるアンチパターン

### ❌ アンチパターン 1: 全環境で同じコード、分岐だらけ
```hcl
# 悪い例
resource "aws_instance" "web" {
  instance_type = var.environment == "prod" ? "t3.large" : 
                  var.environment == "stg" ? "t3.medium" : "t3.small"
  
  monitoring = var.environment == "prod" ? true : false
  
  # 分岐が多すぎて可読性が低い
}
```

### ✅ 推奨パターン: 変数で環境差分を管理
```hcl
# 良い例
resource "aws_instance" "web" {
  instance_type = var.instance_type
  monitoring    = var.enable_detailed_monitoring
}
```

### ❌ アンチパターン 2: ステート共有
```hcl
# 全環境で同じバックエンド = 危険！
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "terraform.tfstate"  # 同じキー！
  }
}
```

### ✅ 推奨パターン: ステート分離
```hcl
# 環境ごとに異なるキー
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "${var.environment}/terraform.tfstate"
  }
}
```

### ❌ アンチパターン 3: ハードコード
```hcl
# 悪い例
resource "aws_db_instance" "main" {
  instance_class = "db.t3.large"  # ハードコード
}
```

### ✅ 推奨パターン: 変数化
```hcl
# 良い例
resource "aws_db_instance" "main" {
  instance_class = var.db_instance_class
}
```

## まとめ

### 小規模プロジェクト（~5リソース）
→ **Workspace方式** で十分

### 中規模プロジェクト（5-50リソース）
→ **ディレクトリ分離 + 共通モジュール**

### 大規模プロジェクト（50+リソース）
→ **モジュール設計 + Terragrunt** または **厳密なディレクトリ分離**

### 最重要ポイント
1. **ステートは完全に分離**
2. **変数で環境差分を吸収**
3. **モジュールでコード再利用**
4. **タグ付けとネーミングの統一**
5. **CI/CDで自動化**
6. **本番は手動承認必須**
