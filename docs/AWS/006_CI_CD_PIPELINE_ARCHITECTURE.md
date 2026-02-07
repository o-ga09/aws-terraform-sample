# CI/CD パイプラインアーキテクチャ

## 概要

このドキュメントは、アプリケーションリポジトリからテラフォームリポジトリへのコンテナイメージタグの更新をトリガーとして、CD パイプラインを自動実行する仕組みについて説明します。

## アーキテクチャ

```
┌─────────────────────────────────┐
│  Application Repository         │
│  (build-container-and-..yaml)   │
└──────────┬──────────────────────┘
           │ 1. Webhook trigger (push)
           │ • main → prod
           │ • staging → stg
           │ • develop → dev
           │ + workflow_dispatch (dev only)
           ▼
┌─────────────────────────────────┐
│  Build & Push Container         │
│  • Docker build                 │
│  • Push to ECR                  │
└──────────┬──────────────────────┘
           │ 2. Update terraform.tfvars
           │ container_image_tag
           ▼
┌─────────────────────────────────┐
│  Terraform Repository           │
│  (deploy-production-aws.yaml)   │
└──────────┬──────────────────────┘
           │ 3. repository_dispatch or push
           │ triggers CD pipeline
           ▼
┌─────────────────────────────────┐
│  Plan & Apply Terraform         │
│  (plan → apply → deploy)        │
└─────────────────────────────────┘
```

## デプロイフロー

### 1. dev 環境

**トリガーパターン:**
- ✅ Application の `develop` ブランチへのpush
- ✅ Application の `develop` ブランチからの `workflow_dispatch` （手動実行）

**実行内容:**
1. アプリケーションリポジトリでコンテナをビルド（タグ: `dev:COMMIT_HASH`）
2. ビルドイメージを ECR にプッシュ
3. terraform リポジトリの `AWS/environments/dev/terraform.tfvars` を更新
   - `container_image_tag = "dev:COMMIT_HASH"`
4. terraform リポジトリが `repository_dispatch` イベント `deploy-dev` をトリガー
5. terraform リポジトリで dev 環境への plan → apply を実行

### 2. stg 環境

**トリガーパターン:**
- ✅ Application の `staging` ブランチへのpush **のみ**

**実行内容:**
1. アプリケーションリポジトリでコンテナをビルド（タグ: `stg:COMMIT_HASH`）
2. ビルドイメージを ECR にプッシュ
3. terraform リポジトリの `AWS/environments/staging/terraform.tfvars` を更新
   - `container_image_tag = "stg:COMMIT_HASH"`
4. terraform リポジトリが `repository_dispatch` イベント `deploy-stg` をトリガー
5. terraform リポジトリで stg 環境への plan → apply を実行

### 3. prod 環境

**トリガーパターン:**
- ✅ Application の `main` ブランチへのpush **のみ**

**実行内容:**
1. アプリケーションリポジトリでコンテナをビルド（タグ: `prod:COMMIT_HASH`）
2. ビルドイメージを ECR にプッシュ
3. terraform リポジトリの `AWS/environments/production/terraform.tfvars` を更新
   - `container_image_tag = "prod:COMMIT_HASH"`
4. terraform リポジトリが `repository_dispatch` イベント `deploy-prod` をトリガー
5. terraform リポジトリで prod 環境への plan → apply を実行
6. **GitHub Environment Protection Rule** により、manual approval が必須

## 必要な設定

### 1. アプリケーションリポジトリ側

#### 1.1 ワークフローファイル配置

アプリケーションリポジトリの `.github/workflows/` ディレクトリに、以下のファイルを配置：
```
.github/workflows/build-container-and-trigger-cd.yaml
```

参考実装: [build-container-and-trigger-cd.yaml](../../.github/workflows/build-container-and-trigger-cd.yaml)

#### 1.2 シークレット設定

GitHub Repository Settings → Secrets and variables → Actions で以下を登録：

- **AWS_ROLE_ECR_PUSH**
  - ECR にイメージをプッシュするための IAM Role ARN
  - OIDC を使用する場合のロールARN

#### 1.3 環境変数設定（ワークフロー内）

`build-container-and-trigger-cd.yaml` 内で以下を設定：

```yaml
env:
  AWS_REGION: ap-northeast-1  # AWS リージョン
  IMAGE_REPO_NAME: aws-terraform-sample-repo  # ECR リポジトリ名
```

### 2. Terraform リポジトリ側

#### 2.1 ワークフローアップデート

既存の `deploy-production-aws.yaml` ワークフローは、以下のトリガーに対応：
- Push to `main` / `develop` branches
- Pull Request to `main` / `develop` branches
- **`repository_dispatch` イベント** （アプリケーション側から）

#### 2.2 terraform.tfvars 管理

**重要:** 各環境の `terraform.tfvars` ファイルは以下のフォーマットで管理：

```hcl
# AWS/environments/{environment}/terraform.tfvars

# ... その他の設定 ...

# Container Image Configuration
container_image_tag = "dev:abc1234"  # CI/CD から動的に更新される
```

**更新形式:**
- `dev` 環境: `dev:COMMIT_HASH`
- `stg` 環境: `stg:COMMIT_HASH`
- `prod` 環境: `prod:COMMIT_HASH`

### 3. AWS IAM とOIDC 設定

#### 3.1 ECR Push Role

アプリケーションリポジトリからの ECR プッシュ用 IAM Role：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:ap-northeast-1:ACCOUNT_ID:repository/aws-terraform-sample-repo"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    }
  ]
}
```

#### 3.2 Terraform Deployment Roles

既存の `AWS_ROLE_dev`, `AWS_ROLE_stg`, `AWS_ROLE_prod` シークレットは継続利用

### 4. GitHub Settings

#### 4.1 環境保護ルール（Production）

terraform リポジトリの Settings → Environments → production で：

- ✅ "Required reviewers" を有効化
- ✅ 承認者のチームまたはユーザを設定

#### 4.2 Deployment Branches Protection

- `allowed-deployment-branches` を `main` に設定

## ワークフロー実行フロー図

### dev 環境デプロイフロー

```
Application Repo
├─ on: push (develop) / workflow_dispatch
├─ Build docker image (dev:COMMIT_HASH)
├─ Push to ECR
├─ Update terraform.tfvars (container_image_tag = "dev:COMMIT_HASH")
├─ Commit & Push to terraform repo (main branch)
└─ Trigger repository_dispatch: deploy-dev
        ↓
Terraform Repo (deploy-production-aws.yaml)
├─ on: repository_dispatch (deploy-dev)
├─ Setup: determine environments = ["dev"]
├─ Plan (dev)
├─ Apply (dev) - No manual approval needed
└─ Notify success/failure
```

### stg 環境デプロイフロー

```
Application Repo
├─ on: push (staging)
├─ Build docker image (stg:COMMIT_HASH)
├─ Push to ECR
├─ Update terraform.tfvars (container_image_tag = "stg:COMMIT_HASH")
├─ Commit & Push to terraform repo (main branch)
└─ Trigger repository_dispatch: deploy-stg
        ↓
Terraform Repo (deploy-production-aws.yaml)
├─ on: repository_dispatch (deploy-stg)
├─ Setup: determine environments = ["stg"]
├─ Plan (stg)
├─ Apply (stg) - No manual approval needed
└─ Notify success/failure
```

### prod 環境デプロイフロー

```
Application Repo
├─ on: push (main)
├─ Build docker image (prod:COMMIT_HASH)
├─ Push to ECR
├─ Update terraform.tfvars (container_image_tag = "prod:COMMIT_HASH")
├─ Commit & Push to terraform repo (main branch)
└─ Trigger repository_dispatch: deploy-prod
        ↓
Terraform Repo (deploy-production-aws.yaml)
├─ on: repository_dispatch (deploy-prod)
├─ Setup: determine environments = ["prod"]
├─ Plan (prod)
├─ Apply (prod) - ✋ Manual approval required (GitHub Environment)
├─ Notify success/failure
└─ Deployed to production
```

## トラブルシューティング

### 1. repository_dispatch が動作しない

**確認項目:**
- アプリケーションリポジトリの GitHub Token が正しいか
- `GITHUB_TOKEN` に repo スコープがあるか
- terraform リポジトリへのアクセス権限があるか

**解決方法:**
```yaml
# build-container-and-trigger-cd.yaml で
- uses: actions/github-script@v7
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}  # デフォルトトークン確認
```

### 2. terraform.tfvars の更新が反映されない

**確認項目:**
- ファイルパスが正しいか（`AWS/environments/{environment}/terraform.tfvars`）
- sed コマンドが正しく実行されているか
- git push が成功しているか

**確認コマンド:**
```bash
# terraform repo で
git log --oneline -n 5 -- AWS/environments/dev/terraform.tfvars
grep "container_image_tag" AWS/environments/dev/terraform.tfvars
```

### 3. Plan は成功するが Apply が失敗する

**確認項目:**
- IAM Role のパーミッションが正しいか
- Terraform State ファイルが破損していないか
- 既存リソースに問題がないか

**確認コマンド:**
```bash
cd AWS/environments/{environment}
terraform plan  # ローカルで実行確認
```

## セキュリティに関する注記

### 1. OIDC 認証の使用

アプリケーションリポジトリと terraform リポジトリの両方で、AWS アクセスは OIDC ベースの認証を使用しています。

詳細は [SECRETS_AND_IMAGES_GUIDE.md](./004_SECRETS_AND_IMAGES_GUIDE.md) を参照

### 2. Secret の取り扱い

- GitHub Secrets に登録された IAM Role ARN は、ワークフロー実行時にのみ使用
- AWS credentials は temporary に制限されている
- Database password などは AWS Secrets Manager または Parameter Store で管理

### 3. Pull Request の取り扱い

PR に対しては plan のみが実行され、apply は実行されません。

```yaml
if: github.event_name != 'pull_request'  # apply は PR で実行しない
```

## 参考資料

- [000_environment_management_best_practice.md](./000_environment_management_best_practice.md)
- [004_SECRETS_AND_IMAGES_GUIDE.md](./004_SECRETS_AND_IMAGES_GUIDE.md)
- [GitHub Actions - Repository Dispatch](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#repository_dispatch)
- [GitHub Actions - Workflow Dispatch](https://docs.github.com/en/actions/using-workflows/manually-running-a-workflow)
