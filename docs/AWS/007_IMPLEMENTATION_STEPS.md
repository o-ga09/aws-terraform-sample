# CI/CD パイプライン実装ガイド

## 概要

このガイドは、アプリケーションリポジトリとterraformリポジトリ間のCI/CDパイプラインを構築するための詳細な実装手順です。

## ステップ 1: Terraform リポジトリの準備

### 1.1 ワークフロー更新の確認

terraform リポジトリの `.github/workflows/deploy-production-aws.yaml` が以下の機能を持つことを確認：

✅ **トリガータイプの判定:**
```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
  repository_dispatch:
    types: [deploy-dev, deploy-stg, deploy-prod]
```

✅ **環境判定ロジック:**
```yaml
setup:
  outputs:
    environments: ${{ steps.set-envs.outputs.environments }}
    trigger_type: ${{ steps.identify-trigger.outputs.trigger_type }}
```

✅ **Apply 条件:**
```yaml
apply-dev:
  if: |
    contains(fromJson(needs.setup.outputs.environments), 'dev') &&
    (github.event_name == 'repository_dispatch' || github.ref == 'refs/heads/develop')
```

### 1.2 terraform.tfvars の確認

各環境のterraform.tfvarsが以下の形式になっていることを確認：

```hcl
# AWS/environments/development/terraform.tfvars
container_image_tag = "latest"

# AWS/environments/staging/terraform.tfvars
container_image_tag = "latest"

# AWS/environments/production/terraform.tfvars
container_image_tag = "latest"
```

### 1.3 GitHub Environment の設定（Production のみ）

terraform リポジトリの Settings → Environments → production で以下を設定：

1. **Required reviewers** をON
   - 承認が必要なユーザ/チームを追加

2. **Deployment branches** を設定
   - `Allow deployments from specific branches`
   - `main` を選択

## ステップ 2: アプリケーションリポジトリの準備

### 2.1 フォルダ構成の作成

アプリケーションリポジトリで以下のフォルダを作成：

```
application-repo/
├── .github/
│   └── workflows/
│       └── build-container-and-trigger-cd.yaml  ← このファイルを作成
├── Dockerfile
├── src/
└── ...
```

### 2.2 ワークフローファイルの配置

`.github/workflows/build-container-and-trigger-cd.yaml` をアプリケーションリポジトリに配置

参照: [build-container-and-trigger-cd.yaml](../../.github/workflows/build-container-and-trigger-cd.yaml)

### 2.3 GitHub Secrets の設定

アプリケーションリポジトリの Settings → Secrets and variables → Actions で以下を登録：

| Secret 名 | 値 | 説明 |
|-----------|---|------|
| `AWS_ROLE_ECR_PUSH` | `arn:aws:iam::ACCOUNT_ID:role/RoleName` | ECR プッシュ用 IAM Role ARN |

**注:** 各シークレットの値は、環境に応じて置き換えてください。

## ステップ 3: AWS IAM ロールの作成

### 3.1 ECR プッシュ用 IAM ロール

**ロール名:** `github-actions-ecr-push`

**信頼ポリシー:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/APPLICATION_REPO:ref:refs/heads/*"
        }
      }
    }
  ]
}
```

**インラインポリシー:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRPushPolicy",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:ap-northeast-1:ACCOUNT_ID:repository/aws-terraform-sample-repo"
    }
  ]
}
```

### 3.2 ECR リポジトリの確認

以下の設定を確認：

```bash
# AWS CLI で確認
aws ecr describe-repositories \
  --repository-names aws-terraform-sample-repo \
  --region ap-northeast-1
```

**確認事項:**
- リポジトリ名: `aws-terraform-sample-repo`
- リージョン: `ap-northeast-1`
- イメージスキャン: `enabled` (推奨)
- タグ不変性: `mutable`

## ステップ 4: デプロイテスト

### 4.1 Dev 環境テスト

**1. アプリケーション側手動実行:**
```bash
# Application リポジトリで
# GitHub UI: Actions → build-container-and-trigger-cd → Run workflow
# Branch: develop
# Trigger: workflow_dispatch
```

**2. 確認項目:**
- ✅ Docker イメージのビルドが成功
- ✅ ECR へのプッシュが成功
- ✅ terraform 側で repository_dispatch イベントが受信
- ✅ terraform リポジトリで plan/apply が実行
- ✅ AWS 側で ECS タスク定義が更新

**3. 確認コマンド:**
```bash
# ECR イメージ確認
aws ecr describe-images \
  --repository-name aws-terraform-sample-repo \
  --region ap-northeast-1 \
  | jq '.imageDetails[] | {tag: .imageTags, pushedAt: .imagePushedAt}'

# ECS タスク定義確認
aws ecs describe-task-definition \
  --task-definition aws-terraform-sample:1 \
  --region ap-northeast-1 \
  | jq '.taskDefinition.containerDefinitions[0].image'
```

### 4.2 Staging 環境テスト

**1. git push実行:**
```bash
# Application リポジトリで
git checkout staging
git commit --allow-empty -m "test: trigger staging deployment"
git push origin staging
```

**2. 確認項目:**
- ✅ Push がワークフロー実行をトリガー
- ✅ terraform リポジトリで staging へのデプロイが実行
- ✅ イメージタグが `stg:COMMIT_HASH` 形式

### 4.3 Production 環境テスト

**1. git push実行:**
```bash
# Application リポジトリで
git checkout main
git commit --allow-empty -m "test: trigger production deployment"
git push origin main
```

**2. 確認項目:**
- ✅ Push がワークフロー実行をトリガー
- ✅ terraform リポジトリで prod plan が表示
- ✅ **Manual approval** が必須
- ✅ 承認後に apply が実行
- ✅ イメージタグが `prod:COMMIT_HASH` 形式

**3. GitHub UI で承認:**
```
terraform リポジトリ → Actions → Apply to Production → Review deployments
→ Approve and deploy
```

## ステップ 5: モニタリングと管理

### 5.1 ワークフロー実行の監視

**GitHub UI での確認:**
1. Application リポジトリ → Actions
   - `build-container-and-trigger-cd` ワークフローの実行状況
2. Terraform リポジトリ → Actions
   - `deploy-production-aws` ワークフローの実行状況

### 5.2 ログの確認

**Application 側:**
```
Actions → build-container-and-trigger-cd → specific run
├── setup
├── build
├── update-terraform
└── notify-result
```

**Terraform 側:**
```
Actions → deploy-production-aws → specific run
├── setup
├── validate
├── plan
├── apply-dev/stg/prod
├── security-scan
└── cost-estimation
```

### 5.3 失敗時の診断

**よくある問題と対処:**

1. **ECR プッシュ失敗**
   ```
   Error: failed to login
   → AWS_ROLE_ECR_PUSH の IAM ロール確認
   → OIDC プロバイダー設定を確認
   ```

2. **repository_dispatch が失敗**
   ```
   Error: resource not found
   → GITHUB_TOKEN のスコープ確認
   → terraform リポジトリへのアクセス権限確認
   ```

3. **terraform apply が失敗**
   ```
   terraform plan は成功するが apply で失敗
   → AWS IAM Role のパーミッション確認
   → リソース競合の確認
   ```

## ステップ 6: 本番運用への移行

### 6.1 チェックリスト

- [ ] 全3環境（dev/stg/prod）でのテストが完了
- [ ] セキュリティスキャンが有効化されている
- [ ] コスト推定が有効化されている
- [ ] GitHub Environment の承認ルールが設定されている
- [ ] 監視アラートが設定されている（必要に応じて）
- [ ] ドキュメント更新が完了
- [ ] チーム全体への周知が完了

### 6.2 ドキュメント更新

チーム向けのドキュメント更新例：

```markdown
# デプロイ手順

## 開発環境 (dev)
1. `develop` ブランチに push するか、workflow_dispatch で手動実行

## ステージング環境 (stg)
1. `staging` ブランチに push

## 本番環境 (prod)
1. `main` ブランチに push
2. terraform リポジトリで apply の承認を実施
3. GitHub Actions でデプロイ完了を確認

詳細は [006_CI_CD_PIPELINE_ARCHITECTURE.md](../docs/AWS/006_CI_CD_PIPELINE_ARCHITECTURE.md) を参照
```

## トラブルシューティング

### 問題：ワークフローが走らない

**原因フロー図:**
```
Push → Webhook 送信 → GitHub Actions トリガー (?)
                          ↓
                   [設定間違い]
                 • パス指定が誤り
                 • ブランチ指定が誤り
                 • ワークフロー構文エラー
```

**対処:**
```bash
# 1. ワークフロー構文の確認
github: 
```

### 問題： `container_image_tag` が更新されない

**原因フロー図:**
```
Update terraform.tfvars → Commit → Push (?)
                                ↓
                         [git 操作エラー]
                      • パスが存在しない
                      • 権限不足
                      • ブランチ異なる
```

**対処:**
```bash
# 1. ファイルを terraform リポジトリで確認
ls -la AWS/environments/{dev,stg,production}/terraform.tfvars

# 2. 最新の更新を確認
git log --oneline -n 5 -- AWS/environments/*/terraform.tfvars

# 3. sed コマンドをローカルで テスト
sed -i.bak 's/container_image_tag[[:space:]]*=[[:space:]]*"[^"]*"/container_image_tag = "dev:test123"/' AWS/environments/dev/terraform.tfvars
```

### 問題： Manual approval が表示されない

**原因フロー図:**
```
Production apply → GitHub Environment check (?)
                        ↓
                 [設定不足]
              • environment が未設定
              • required reviewers がない
              • ブランチ制限が厳しい
```

**対処:**
1. terraform リポジトリ Settings → Environments → production
2. "Required reviewers" が ON になっているか確認
3. 該当ユーザ/チームが追加されているか確認

## まとめ

このCI/CDパイプラインにより、以下が実現されます：

| 環境 | トリガー | 特徴 |
|-----|--------|------|
| **dev** | push (develop) + workflow_dispatch | 最速デプロイ、手動実行可能 |
| **stg** | push (staging) のみ | ステージング環境として段階的テスト |
| **prod** | push (main) のみ + manual approval | 高い安全性、承認ワークフロー必須 |

詳細は [006_CI_CD_PIPELINE_ARCHITECTURE.md](../docs/AWS/006_CI_CD_PIPELINE_ARCHITECTURE.md) を参照してください。
