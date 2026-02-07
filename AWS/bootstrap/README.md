# Terraform State Backend Bootstrap

このディレクトリは、Terraform の State を S3 に管理するための初期リソースを作成します。

## 概要

以下のリソースを作成します：

### S3 バケット
- **State 用 S3 バケット**: Terraform State ファイルを保管
  - 暗号化: 有効（AES256）
  - バージョニング: 有効（状態の履歴管理）
  - ブロックパブリックアクセス: 有効
  - ログ: State 用 S3 バケットに保存

- **ログ用 S3 バケット**: State バケットのログを保管

### DynamoDB テーブル
- **State Lock テーブル**: `terraform-lock`
  - Terraform 実行時の競合を防止
  - 複数開発者が同時に `terraform apply` できないように制御

## 実行手順

### 前提条件

```bash
# AWS 認証情報の設定
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="ap-northeast-1"

# または aws configure
aws configure
```

### 初期化と実行

```bash
# 手動実行の場合
cd AWS/bootstrap

# Terraform の初期化
terraform init

# リソース作成内容を確認
terraform plan

# リソースを作成
terraform apply

# 出力値を確認（Account ID が必要）
terraform output
```

### 出力例

```
state_bucket_name = "terraform-state-123456789012-ap-northeast-1"
state_bucket_arn = "arn:aws:s3:::terraform-state-123456789012-ap-northeast-1"
dynamodb_table_name = "terraform-lock"
aws_account_id = "123456789012"
aws_region = "ap-northeast-1"
```

## 各環境の初期化

Bootstrap 完了後、各環境を初期化します。出力の `aws_account_id` を使用：

```bash
# Production
cd ../environments/production
terraform init -backend-config="bucket=terraform-state-<aws_account_id>-ap-northeast-1"

# Staging
cd ../staging
terraform init -backend-config="bucket=terraform-state-<aws_account_id>-ap-northeast-1"

# Development
cd ../development
terraform init -backend-config="bucket=terraform-state-<aws_account_id>-ap-northeast-1"
```

## S3 バケット内のファイル構造

> [!NOTE]
> `.tfstate `ファイルが作成されるのは、各環境で `terraform apply` を実行した後です。

```
s3://terraform-state-<aws_account_id>-ap-northeast-1/
├── production/
│   └── terraform.tfstate          # Production 環境の State
├── staging/
│   └── terraform.tfstate          # Staging 環境の State
└── development/
    └── terraform.tfstate          # Development 環境の State
```

## 重要な注意事項

### セキュリティ

1. **バケットのブロック**: パブリックアクセスは完全にブロック
2. **暗号化**: すべての State ファイルは AES256 で暗号化
3. **IAM ポリシー**: State バケットへのアクセスを制限したい場合は IAM ポリシーを追加してください

### ロック機構

DynamoDB テーブル（`terraform-lock`）は、複数の Terraform プロセスが同時に実行されるのを防ぎます：

```bash
# ロック状態を確認
aws dynamodb scan --table-name terraform-lock

# 不正なロックをクリア（慎重に実行）
aws dynamodb delete-item --table-name terraform-lock \
  --key '{"LockID": {"S": "terraform-state-<aws_account_id>-ap-northeast-1/production/terraform.tfstate"}}'
```

## クリーンアップ

**警告: State ファイルが削除されます！**

```bash
# 環境の State を S3 から削除したい場合
aws s3 rm s3://terraform-state-<aws_account_id>-ap-northeast-1/production/

# すべてのリソースを削除（Bootstrap含む）
terraform destroy
```

## トラブルシューティング

### S3 バケット名の競合

```
Error: Error creating S3 bucket: BucketAlreadyExists
```

対策: S3 バケット名はグローバルに一意である必要があります。Account ID が自動的に含まれているので、通常は発生しません。

### DynamoDB ロックの取得失敗

```
Error: Error acquiring the state lock
```

対策: 以下を確認してください
- DynamoDB テーブル（`terraform-lock`）が存在するか
- IAM に `dynamodb:PutItem` 権限があるか

### バケットへのアクセス拒否

```
Error: error reading S3 Bucket (bucket-name): AccessDenied
```

対策:
- AWS 認証情報が正しいか確認
- IAM に S3 バケットへのアクセス権限があるか確認

## 参考資料

- [Terraform S3 Backend](https://www.terraform.io/language/settings/backends/s3)
- [AWS S3 State Lock](https://www.terraform.io/language/settings/backends/s3#dynamodb_table)
