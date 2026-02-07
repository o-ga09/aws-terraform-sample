# シークレット管理とコンテナイメージ動的指定ガイド

このガイドでは、Terraform設定でDB パスワードをAWS Systems Manager Parameter Storeから取得し、コンテナイメージのタグを動的に指定する方法について説明します。

## 概要

### 対応する機能

1. **DBパスワード管理**
   - ✅ プレーンテキスト（非推奨）
   - ✅ AWS Secrets Manager
   - ✅ AWS Systems Manager Parameter Store

2. **コンテナイメージ指定**
   - ✅ 固定イメージURI
   - ✅ 動的タグ（commit hash、git tagなど）

---

## 1️⃣ DBパスワード設定

### AWS Systems Manager Parameter Store を使用（推奨）

#### Step 1: Parameter Store にパスワードを保存

```bash
# セキュアなパラメータとしてパスワードを保存
aws ssm put-parameter \
  --name "/database/production/db_password" \
  --value "P@ssw0rd" \
  --type "SecureString" \
  --key-id "alias/aws/ssm" \
  --region ap-northeast-1

# 開発環境の場合
aws ssm put-parameter \
  --name "/database/development/db_password" \
  --value "DevPassword123!" \
  --type "SecureString" \
  --region ap-northeast-1

# ステージング環境の場合
aws ssm put-parameter \
  --name "/database/staging/db_password" \
  --value "StagingPassword123!" \
  --type "SecureString" \
  --region ap-northeast-1
```

#### Step 2: terraform.tfvars で設定

**production環境の場合:**

```hcl
# AWS Systems Manager Parameter Store を使用する場合
use_parameter_store           = true
parameter_store_password_name = "/database/production/db_password"

# プレーンテキストは指定しない
master_password               = null
```

**development環境の場合:**

```hcl
use_parameter_store           = true
parameter_store_password_name = "/database/development/db_password"
master_password               = null
```

#### Step 3: IAM 権限設定

ECS タスク実行ロールと Terraform 実行ユーザーに SSM パラメータの読み取り権限を追加：

```bash
# Terraform実行ユーザー用のポリシー
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:ap-northeast-1:ACCOUNT_ID:parameter/database/*/db_password"
    }
  ]
}

# RDS プロビジョニング時のポリシー
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter"
      ],
      "Resource": "arn:aws:ssm:ap-northeast-1:ACCOUNT_ID:parameter/database/*/db_password"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:ap-northeast-1:ACCOUNT_ID:key/*"
    }
  ]
}
```

### AWS Secrets Manager を使用

#### Step 1: Secrets Manager にシークレットを保存

```bash
# JSON形式でシークレットを保存
aws secretsmanager create-secret \
  --name "rds/production/db_password" \
  --secret-string '{"password":"YourSecurePassword123!"}' \
  --region ap-northeast-1
```

#### Step 2: terraform.tfvars で設定

```hcl
# AWS Secrets Manager を使用する場合
use_secrets_manager       = true
secrets_manager_secret_name = "rds/production/db_password"

# 他のオプションは無視される
use_parameter_store       = false
master_password           = null
```

### プレーンテキストパスワード（非推奨）

```hcl
# どちらのシークレット管理も使用しない場合
use_parameter_store = false
use_secrets_manager = false

# プレーンテキストパスワードを指定（開発環境のみ推奨）
master_password = "ChangeMe!2024"
```

**⚠️ 警告**: `terraform.tfvars` にプレーンテキストのパスワードを記載することは強く非推奨です。本番環境では必ず Secrets Manager または Parameter Store を使用してください。

---

## 2️⃣ コンテナイメージの動的タグ指定

### 方法1: 固定イメージURI を指定

```hcl
# terraform.tfvars
container_image = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:v1.0.0"

# 以下は無視される
container_image_registry   = ""
container_image_repository = ""
container_image_tag        = "latest"
```

### 方法2: コンポーネント指定（推奨 - 動的タグに対応）

```hcl
# terraform.tfvars
container_image            = ""
container_image_registry   = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com"
container_image_repository = "myapp"
container_image_tag        = "latest"
```

**構築されるイメージURI:**
```
123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:latest
```

### 方法3: 動的タグ指定（CI/CD パイプラインから）

#### 例1: Commit Hash を含む

```bash
# CI/CDパイプライン（例：GitHub Actions）
export COMMIT_HASH=$(git rev-parse --short HEAD)

terraform apply \
  -var="container_image_registry=123456789012.dkr.ecr.ap-northeast-1.amazonaws.com" \
  -var="container_image_repository=myapp" \
  -var="container_image_tag=production:${COMMIT_HASH}"
```

**構築されるイメージURI:**
```
123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:production:abc123d
```

#### 例2: 環境名 + Commit Hash + タイムスタンプ

```bash
export COMMIT_HASH=$(git rev-parse --short HEAD)
export TIMESTAMP=$(date +%Y%m%d%H%M%S)

terraform apply \
  -var="container_image_registry=123456789012.dkr.ecr.ap-northeast-1.amazonaws.com" \
  -var="container_image_repository=myapp" \
  -var="container_image_tag=prod-${COMMIT_HASH}-${TIMESTAMP}"
```

**構築されるイメージURI:**
```
123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:prod-abc123d-20240207143025
```

### GitHub Actions での自動化例

`.github/workflows/deploy.yml`:

```yaml
name: Deploy to ECS

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Get commit hash
        run: echo "COMMIT_HASH=$(git rev-parse --short HEAD)" >> $GITHUB_ENV
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-northeast-1
      
      - name: Build and push Docker image
        run: |
          aws ecr get-login-password --region ap-northeast-1 | \
            docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com
          
          docker build -t myapp:${{ env.COMMIT_HASH }} .
          docker tag myapp:${{ env.COMMIT_HASH }} 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:production:${{ env.COMMIT_HASH }}
          docker push 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:production:${{ env.COMMIT_HASH }}
      
      - name: Deploy with Terraform
        working-directory: AWS/environments/production
        run: |
          terraform init
          terraform apply \
            -auto-approve \
            -var="container_image_registry=123456789012.dkr.ecr.ap-northeast-1.amazonaws.com" \
            -var="container_image_repository=myapp" \
            -var="container_image_tag=production:${{ env.COMMIT_HASH }}"
```

---

## 3️⃣ 設定優先順序

### DBパスワード

1. **`use_secrets_manager = true`** → Secrets Manager から取得
2. **`use_parameter_store = true`** → Parameter Store から取得
3. **それ以外** → `master_password` 変数を使用

### コンテナイメージ

1. **`container_image` が指定されている** → そのまま使用
2. **`container_image_registry` と `container_image_repository` が指定されている** 
   → `{registry}/{repository}:{tag}` の形式で組み立て
3. **上記以外** → フォールバック: `nginx:latest`

---

## 4️⃣ 環境別推奨設定

### Production 環境

```hcl
# terraform.tfvars (production)
use_parameter_store           = true
parameter_store_password_name = "/database/production/password"
master_password               = null

container_image             = ""
container_image_registry    = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com"
container_image_repository  = "myapp"
container_image_tag         = "production:abc123d"  # CI/CDパイプラインから動的に設定
```

### Staging 環境

```hcl
# terraform.tfvars (staging)
use_parameter_store           = true
parameter_store_password_name = "/database/staging/password"
master_password               = null

container_image             = ""
container_image_registry    = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com"
container_image_repository  = "myapp"
container_image_tag         = "staging:abc123d"  # CI/CDパイプラインから動的に設定
```

### Development 環境

```hcl
# terraform.tfvars (development)
use_parameter_store           = false
use_secrets_manager           = false
master_password               = "DevPassword123!"  # 開発環境なので簡易設定

container_image             = ""
container_image_registry    = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com"
container_image_repository  = "myapp"
container_image_tag         = "latest"  # または development:abc123d
```

---

## 5️⃣ トラブルシューティング

### Parameter Store アクセス エラー

```
Error: Error creating DB Cluster: InvalidParameterValue: password is not a valid...
```

**原因**: Terraform がParameter Store からパスワードを取得できていない

**対処法**:
1. IAM権限を確認
2. パラメータ名が正しいか確認: `aws ssm get-parameter --name "/database/production/password"`
3. パスワードの形式を確認

### コンテナイメージが古いバージョンで起動

```
ERROR: Image not found: 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:old-tag
```

**原因**: Terraform の `-var` 指定が反映されていない

**対処法**:
```bash
# デバッグコマンド
terraform plan -var="container_image_tag=production:new-hash"

# キャッシュをクリア
terraform refresh
```

### Secrets Manager JSON形式エラー

```
Error: Error creating DB Cluster: invalid password format
```

**原因**: Secrets Manager に保存されたJSONの形式が不正

**対処法**:
```bash
# 正しい形式で再作成
aws secretsmanager update-secret \
  --secret-id "rds/production/password" \
  --secret-string '{"password":"NewPassword123!"}'
```

---

## 6️⃣ セキュリティベストプラクティス

✅ **やるべきこと**:
- 本番環境では Secrets Manager または Parameter Store を使用
- IAM ロールで最小限の権限を付与
- パラメータストアのアクセスログを監視
- terraform.tfvars を `.gitignore` に追加
- sensitive = true を password変数に設定

❌ **やってはいけないこと**:
- terraform.state ファイルをGitにコミット
- パスワードをコード内にハードコード
- Secrets/Parameter Store への全権限アクセス
- production と development で同じパスワードを使用

---

## 参考資料

- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/ja_jp/secretsmanager/latest/userguide/intro.html)
- [Terraform AWS RDS Module](https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest)
- [Terraform Sensitive Variables](https://www.terraform.io/language/state/sensitive-data)
