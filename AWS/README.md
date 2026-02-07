# Production Environment Configuration

このディレクトリには、AWS上でproduction環境を構築するためのTerraformコードが含まれています。

## 構成

以下のAWSリソースがTerraformモジュールを使用して自動的にデプロイされます：

### VPC Module
- VPC（Virtual Private Cloud）
- Internet Gateway
- Public Subnets（複数AZ対応）
- Private Subnets（複数AZ対応）
- Database Subnets
- Management Subnets
- NAT Gateways
- Route Tables

### ALB Module
- Application Load Balancer
- Target Groups
- Listeners (HTTP/HTTPS)
- Access Logs (オプション)

### ECR Module
- ECR Repository
- Lifecycle Policy（イメージ保持数の制御）
- Image Scanning

### ECS Module
- ECS Cluster
- Task Definition
- ECS Service
- Auto Scaling
- CloudWatch Log Group

### RDS Module
- Aurora MySQL Cluster
- DB Instances（マルチAZ対応）
- DB Subnet Group
- Backup Configuration

### Security Groups
- ALB Security Group（HTTP/HTTPS）
- ECS Security Group（ALBからのアクセス許可）
- RDS Security Group（ECSからのアクセス許可）

## 使用方法

### 0. S3 State バックエンド管理の初期化（初回のみ）

本番環境では、Terraform State をローカルではなく S3 に保管することを推奨します。

#### Step 1: Bootstrap リソースの作成

```bash
# bootstrap ディレクトリに移動
cd AWS/bootstrap

# Terraformの初期化（ローカルstateを使用）
terraform init

# S3バケットとDynamoDBテーブルを作成
terraform apply

# 出力から AWS Account ID を確認
terraform output aws_account_id
```

出力例：
```
state_bucket_name = "terraform-state-123456789012-ap-northeast-1"
state_bucket_arn = "arn:aws:s3:::terraform-state-123456789012-ap-northeast-1"
dynamodb_table_name = "terraform-lock"
aws_account_id = "123456789012"
```

#### Step 2: 各環境の初期化

S3バックエンドを使用するように各環境を初期化します。bootstrap出力の `aws_account_id` と `aws_region` を使用してください。

```bash
# Production環境
cd AWS/environments/production
terraform init -backend-config="bucket=terraform-state-123456789012-ap-northeast-1"

# Staging環境
cd ../staging
terraform init -backend-config="bucket=terraform-state-123456789012-ap-northeast-1"

# Development環境
cd ../development
terraform init -backend-config="bucket=terraform-state-123456789012-ap-northeast-1"
```

#### Step 3: バックエンド設定の確認

```bash
# 現在のバックエンド設定を確認
terraform show

# S3上のstateファイルを確認（AWS CLI）
aws s3 ls s3://terraform-state-123456789012-ap-northeast-1/
```

### 1. 必要な準備

```bash
# AWS認証情報の設定
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="ap-northeast-1"

# NOTE: S3バックエンドの初期化がまだの場合は、上記の"Step 0. S3 State バックエンド管理の初期化"を実行してください
```

### 2. 変数ファイルの作成

```bash
# サンプルファイルからコピー
cp terraform.tfvars.example terraform.tfvars

# 必要な値を編集
vim terraform.tfvars
```

**重要な設定項目：**
- `project_name`: プロジェクト名
- `container_image`: デプロイするコンテナイメージURI
- `master_password`: RDSマスターパスワード（安全な値に変更）
- `certificate_arn`: HTTPS有効化時のSSL証明書ARN

### 3. Terraformの初期化と計画（S3バックエンド設定済み）

```bash
# ディレクトリを変更
cd AWS/environments/production

# 注: terraform init を実行する際、S3バックエンド設定が済んでいるはずです
# もしまだの場合は、上記"Step 0"を実行してください

# Terraformの初期化
terraform init

# 計画を確認
terraform plan
```

### 4. インフラストラクチャの構築

```bash
# リソースを作成
terraform apply

# 確認を求められたら "yes" を入力
```

### 5. 出力値の確認

```bash
# 重要なリソース情報を表示
terraform output

# 特定の出力値を取得
terraform output alb_dns_name
```

## 出力例

```
Outputs:

alb_dns_name = "myapp-alb-123456789.ap-northeast-1.elb.amazonaws.com"
ecr_repository_url = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp"
ecs_cluster_name = "myapp-ecs-cluster"
rds_cluster_endpoint = "myapp-rds-cluster.cluster-xxxxxxxxx.ap-northeast-1.rds.amazonaws.com"
```

## 設定のカスタマイズ

### HTTPS/SSL証明書の有効化

```hcl
enable_https    = true
certificate_arn = "arn:aws:acm:ap-northeast-1:123456789012:certificate/..."
```

### RDS Serverlessの使用

Aurora Serverlessv2を使用する場合：

```hcl
is_serverless  = true
min_capacity   = 0.5
max_capacity   = 2
```

### Auto Scalingの設定

ECS タスクの自動スケーリング：

```hcl
enable_auto_scaling = true
min_task_count      = 2
max_task_count      = 8
```

### コンテナ環境変数の設定

```hcl
container_environment = {
  "ENVIRONMENT" = "production"
  "LOG_LEVEL"   = "info"
  "DB_HOST"     = "myapp-rds-cluster.cluster-xxx.ap-northeast-1.rds.amazonaws.com"
}
```

## リソースの破棄

**警告：This will delete all production resources!**

```bash
terraform destroy

# 確認を求められたら "yes" を入力
```

## トラブルシューティング

### モジュールが見つからない

```bash
# Terraformキャッシュをクリアして再初期化
rm -rf .terraform/
terraform init
```

### リソースの更新の確認

```bash
# 現在の状態を確認
terraform state list
terraform state show <resource-name>
```

### 詳細ログの確認

```bash
# DEBUG レベルでログを出力
TF_LOG=DEBUG terraform plan
```

### モジュール出力属性エラーの解決

**エラー例：**
```
Error: Unsupported attribute
on outputs.tf line 10, in output "vpc_cidr":
  10:   value       = module.vpc.vpc_cidr_block
This object does not have an attribute named "vpc_cidr_block".
```

**原因：** モジュール定義の出力属性名と `outputs.tf` で参照している属性名が異なっている

**解決方法：** 各モジュールの `outputs.tf` で定義されている正しい属性名を確認して、参照を修正してください。

```bash
# モジュール出力の確認例
cat AWS/modules/vpc/outputs.tf
cat AWS/modules/ecs/outputs.tf
cat AWS/modules/rds/outputs.tf
```

**よくある修正例：**
- `module.vpc.vpc_cidr_block` → `module.vpc.vpc_cidr`
- `module.vpc.nat_gateway_public_ips` → `module.vpc.nat_gateway_ids`
- `module.ecs.cloudwatch_log_group_name` → `module.ecs.log_group_name`
- `module.rds.reader_endpoint` → `module.rds.cluster_reader_endpoint`

### Terraform ブロック定義エラーの解決

**エラー例：**
```
Error: Unsupported block type
on modules/alb/alb.tf line 82, in resource "aws_lb_listener" "http":
  82:     dynamic "target_group_arn" {
Blocks of type "target_group_arn" are not expected here.
```

**原因：** `default_action` ブロック内で `dynamic "target_group_arn"` が使用されているが、`target_group_arn` は直接属性として指定する必要があります。

**解決方法：** `dynamic` ブロックを削除し、条件演算子を使用して直接属性を指定してください。

```hcl
# ✗ 間違い
default_action {
  type = var.enable_https ? "redirect" : "forward"
  
  dynamic "target_group_arn" {
    for_each = !var.enable_https ? [aws_lb_target_group.main.arn] : []
    content {
      target_group_arn = target_group_arn.value
    }
  }
}

# ✓ 正しい
default_action {
  type = var.enable_https ? "redirect" : "forward"
  target_group_arn = !var.enable_https ? aws_lb_target_group.main.arn : null
  
  dynamic "redirect" {
    for_each = var.enable_https ? [1] : []
    content {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

## ベストプラクティス

1. **S3バックエンド管理**: 本番環境では Terraform State を S3 に保管し、DynamoDB でロック機構を実装
   - State ファイルは暗号化して S3 に保存
   - バージョニングを有効化してロールバック可能に
   - 複数開発者での同時実行を DynamoDB ロックで制御

2. **パスワード管理**: `terraform.tfvars` に機密情報を直接記述せず、以下を使用
   - AWS Secrets Manager- パラメータストア
   - 環境変数

3. **変更管理**: 常に以下のフローを実施
   - `terraform plan` で変更を確認
   - PR で `terraform plan` の出力をレビュー
   - `terraform apply` で本番適用

4. **タグ管理**: リソースに適切なタグを付与
   - Environment: production/staging/development
   - Project: プロジェクト名
   - Owner: 所有者
   - CostCenter: コスト配分用

5. **State ファイル管理**:
   - `.gitignore` に `*.tfstate` と `*.tfstate.*` を追加
   - State ファイルを Git に commit しない
   - バックアップと復旧手順を整備

## 参考ドキュメント

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Terraform モジュール](../../modules/)
- [AWS VPC](https://docs.aws.amazon.com/vpc/)
- [AWS ECR](https://docs.aws.amazon.com/ecr/)
- [AWS ECS](https://docs.aws.amazon.com/ecs/)
- [AWS RDS Aurora](https://docs.aws.amazon.com/rds/latest/userguide/Aurora.html)
