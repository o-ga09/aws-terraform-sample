# リソース重複エラーのトラブルシューティングガイド

このガイドは、Terraform実行時に「リソースが既に存在する」というエラーが発生した場合の対応方法を説明します。

## 📋 概要

Terraformで`terraform apply`を実行する際に、以下のようなエラーが発生することがあります：

- `ResourceAlreadyExistsException`
- `InvalidGroup.Duplicate`
- `DBParameterGroupAlreadyExists`
- `EntityAlreadyExists`

これらは、Terraform管理下にはないが、AWS上に既に存在するリソースを作成しようとした場合に発生します。

---

## 🔍 エラーの原因

### 1. **State Fileとの不整合**
   - Terraformのstate fileにリソース情報が記録されていない
   - 別のTerraformプロジェクトで作成されたリソースが残っている
   - 手動でAWSコンソールから作成したリソース

### 2. **環境設定の問題**
   - 複数の環境（dev/staging/production）で同じstate fileを使用している
   - リージョンの設定ミス
   - AWSアカウントの設定ミス

### 3. **破棄処理の失敗**
   - 以前のデプロイで`terraform destroy`が完全に完了していない
   - ロック機構によって削除がスキップされた

---

## 🛠️ 解決策

### 方法1: リソースをTerraformで管理（推奨）

既に存在するリソースをTerraformのstate fileにインポートします。

#### Step 1: リソースIDを確認

```bash
# Security Group IDの確認
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=aws-terraform-sample-alb-sg" \
  --region ap-northeast-1 \
  --query 'SecurityGroups[0].GroupId' \
  --output text

# ECR Repository URIの確認
aws ecr describe-repositories \
  --repository-names aws-terraform-sample-repo \
  --region ap-northeast-1 \
  --query 'repositories[0].repositoryUri' \
  --output text

# IAM Roleの確認
aws iam get-role \
  --role-name aws-terraform-sample-ecs-task-execution-role-production \
  --query 'Role.Arn' \
  --output text

# RDS Cluster Parameter Groupの確認
aws rds describe-db-cluster-parameter-groups \
  --db-cluster-parameter-group-name aws-terraform-sample-params-production \
  --region ap-northeast-1
```

#### Step 2: terraform importコマンドでインポート

```bash
# Security Group のインポート
terraform import aws_security_group.alb sg-xxxxxxxx

# ECR Repository のインポート
terraform import 'module.ecr.aws_ecr_repository.main' aws-terraform-sample-repo

# CloudWatch Logs Log Group のインポート（ECS）
terraform import 'module.ecs.aws_cloudwatch_log_group.ecs' /ecs/aws-terraform-sample-production

# IAM Role のインポート（ECS Task Execution）
terraform import 'module.ecs.aws_iam_role.ecs_task_execution_role' aws-terraform-sample-ecs-task-execution-role-production

# IAM Role のインポート（ECS Task）
terraform import 'module.ecs.aws_iam_role.ecs_task_role' aws-terraform-sample-ecs-task-role-production

# RDS Cluster Parameter Group のインポート
terraform import 'module.rds.aws_rds_cluster_parameter_group.main' aws-terraform-sample-params-production

# CloudWatch Logs Log Group のインポート（RDS Error）
terraform import 'module.rds.aws_cloudwatch_log_group.aurora[\"error\"]' /aws/rds/cluster/aws-terraform-sample-production/error

# CloudWatch Logs Log Group のインポート（RDS Slowquery）
terraform import 'module.rds.aws_cloudwatch_log_group.aurora[\"slowquery\"]' /aws/rds/cluster/aws-terraform-sample-production/slowquery

# IAM Role のインポート（RDS Monitoring）
terraform import 'module.rds.aws_iam_role.rds_monitoring' aws-terraform-sample-rds-monitoring-role-production
```

#### Step 3: インポート後の確認

```bash
# State fileを確認
terraform state list

# 特定のリソースを詳細確認
terraform state show 'module.ecr.aws_ecr_repository.main'

# 構成と現在のStateの差分を確認
terraform plan
```

**⚠️ 注意**: インポート後、`terraform plan`で差分がないか確認してください。差分がある場合は、Terraformコードを調整する必要があります。

---

### 方法2: 既存リソースを削除してTerraformで再作成

既存リソースが重要でない場合、またはリセットが必要な場合：

```bash
# AWS CLIで既存リソースを削除（例：Security Group）
aws ec2 delete-security-group \
  --group-id sg-xxxxxxxx \
  --region ap-northeast-1

# CloudWatch Logs Log Groupを削除
aws logs delete-log-group \
  --log-group-name "/ecs/aws-terraform-sample-production" \
  --region ap-northeast-1

# IAM Roleを削除
aws iam delete-role \
  --role-name aws-terraform-sample-ecs-task-execution-role-production

# RDS Cluster Parameter Groupを削除
aws rds delete-db-cluster-parameter-group \
  --db-cluster-parameter-group-name aws-terraform-sample-params-production \
  --region ap-northeast-1

# ECR Repositoryを削除（リポジトリが空の場合）
aws ecr delete-repository \
  --repository-name aws-terraform-sample-repo \
  --region ap-northeast-1
```

その後、Terraformで再作成：

```bash
terraform plan
terraform apply
```

---

### 方法3: State manuallyで削除（避けるべき）

Terraformのstate fileから特定のリソースを削除します（慎重に使用）：

```bash
# State fileからリソースを削除（ただし、AWS上には残る）
terraform state rm 'module.ecr.aws_ecr_repository.main'

# 複数のリソースを一度に削除する場合
terraform state rm \
  'module.ecs.aws_cloudwatch_log_group.ecs' \
  'module.ecs.aws_iam_role.ecs_task_execution_role' \
  'module.ecs.aws_iam_role.ecs_task_role'
```

**⚠️ 警告**: この方法を使用すると、Terraform管理外のリソースがAWS上に残ります。後で管理が復雑になる可能性があります。

---

## 🔐 本番環境でのベストプラクティス

### 1. **State Fileの管理**

```bash
# 環境ごとに異なるState Fileを使用
# AWS/environments/production/backend.tf
terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state"
    key            = "production/terraform.tfstate"  # 環境ごとに異なるパス
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# AWS/environments/staging/backend.tf
terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state"
    key            = "staging/terraform.tfstate"    # 異なるパス
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 2. **リソース命名規則の統一**

```bash
# terraform.tfvars で統一された命名規則を使用
project_name = "aws-terraform-sample"
environment  = "production"

# modules/ecr/variables.tf
variable "repository_name" {
  description = "ECR Repository name"
  default     = "${var.project_name}-repo"
}
```

### 3. **IAMポリシーで保護**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup"
      ],
      "Resource": "arn:aws:ec2:*:*:security-group/*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/ManagedBy": ["terraform"]
        }
      }
    }
  ]
}
```

### 4. **事前チェックリスト**

Terraformを実行する前に確認：

- [ ] 正しい環境に対して実行しているか（dev/staging/prod）
- [ ] 正しいAWSアカウントにログインしているか
- [ ] 正しいリージョンを指定しているか
- [ ] `terraform plan`の出力を確認したか
- [ ] State fileがロックされていないか
- [ ] リソース命名に衝突がないか

---

## 📊 見分け方

| エラータイプ | リソース | 解決方法 |
|-----------|---------|--------|
| `InvalidGroup.Duplicate` | Security Group | Import or Delete |
| `RepositoryAlreadyExistsException` | ECR Repository | Import or Delete |
| `ResourceAlreadyExistsException` | CloudWatch Logs | Import or Delete |
| `EntityAlreadyExists` | IAM Role | Import or Delete |
| `DBParameterGroupAlreadyExists` | RDS Parameter Group | Import or Delete |

---

## 🔄 完全なリセットが必要な場合

以下のコマンドで、State file内のすべてのリソースをAWSから削除します：

```bash
# ⚠️ 本番環境では絶対に実行しないでください
terraform destroy

# 確認プロンプトで "yes" と入力します
```

その後、新たに`terraform apply`を実行します：

```bash
terraform apply
```

---

## 📞 トラブルシューティング

### インポート時の一般的なエラー

#### エラー: `resource address is not valid`

```bash
# ❌ 間違った形式
terraform import aws_security_group.alb aws-terraform-sample-alb-sg

# ✅ 正しい形式
terraform import aws_security_group.alb sg-xxxxxxxx
```

#### エラー: `resource already exists in state`

既にState fileに存在するリソースをインポートしようとした：

```bash
# 既存のState entryを削除してから再度インポート
terraform state rm aws_security_group.alb
terraform import aws_security_group.alb sg-xxxxxxxx
```

#### エラー: `error reading resource`

インポート後、リソースの属性をTerraformコードと一致させる必要があります。

```bash
# 現在のState内容を確認
terraform state show aws_security_group.alb

# Terraformコードと比較して、不一致な属性を修正
```

---

## 🎯 まとめ

| 状況 | 推奨アクション |
|-----|--------------|
| 既存リソースを引き継ぎたい | `terraform import` |
| 既存リソースは不要 | 削除 → `terraform apply` |
| 本番環境の完全リセット | `terraform destroy` → `terraform apply` |
| 試験的な環境 | 別のState fileで管理 |

正しい対応を選択することで、Terraform管理の安全性と効率性が向上します。
