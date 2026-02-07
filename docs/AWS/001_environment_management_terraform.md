# Terraform 環境別管理の実践ガイド

Production、Staging、Developmentの3環境を効率的に管理するTerraform構成です。

## 🏗️ ディレクトリ構成

```
terraform/
├── modules/                    # 再利用可能なモジュール
│   ├── vpc/                   # VPCモジュール
│   ├── alb/                   # ALBモジュール
│   └── ecs/                   # ECSモジュール
├── environments/              # 環境別設定
│   ├── prod/                  # 本番環境
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── backend.tf
│   │   └── outputs.tf
│   ├── stg/                   # ステージング環境
│   └── dev/                   # 開発環境
├── .github/workflows/         # CI/CD
│   └── terraform.yml
├── Makefile                   # 便利なコマンド集
├── BEST_PRACTICES.md         # ベストプラクティス
└── ENVIRONMENT_COMPARISON.md # 環境比較表
```

## 🚀 クイックスタート

### 1. 前提条件

```bash
# 必須
- Terraform >= 1.6.0
- AWS CLI
- make

# オプション（推奨）
- terraform-docs  # ドキュメント生成
- tfsec          # セキュリティスキャン
- infracost      # コスト見積もり
```

### 2. S3バックエンドの準備

```bash
# S3バケット作成
aws s3 mb s3://myapp-terraform-state --region ap-northeast-1

# バージョニング有効化
aws s3api put-bucket-versioning \
  --bucket myapp-terraform-state \
  --versioning-configuration Status=Enabled

# 暗号化有効化
aws s3api put-bucket-encryption \
  --bucket myapp-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# DynamoDBテーブル作成（ステートロック用）
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-1
```

### 3. 環境変数の設定

各環境の `terraform.tfvars` を編集：

```bash
# 開発環境
vim environments/dev/terraform.tfvars

# ステージング環境
vim environments/stg/terraform.tfvars

# 本番環境
vim environments/prod/terraform.tfvars
```

### 4. デプロイ

```bash
# 開発環境
make init ENV=dev
make plan ENV=dev
make apply ENV=dev

# ステージング環境
make init ENV=stg
make plan ENV=stg
make apply ENV=stg

# 本番環境（承認プロンプトあり）
make init ENV=prod
make plan ENV=prod
make apply ENV=prod
```

## 📋 Makefileコマンド一覧

### 基本コマンド

```bash
# ヘルプ表示
make help

# 初期化
make init ENV=dev

# プラン実行
make plan ENV=dev

# 適用（承認あり）
make apply ENV=dev

# 自動適用（CI/CD用）
make apply-auto ENV=dev

# 削除
make destroy ENV=dev

# 出力表示
make output ENV=dev
```

### 検証・フォーマット

```bash
# コードフォーマット
make fmt

# 検証
make validate ENV=dev

# 全環境の検証
make validate-all

# フォーマットチェック（CI用）
make fmt-check
```

### 高度なコマンド

```bash
# セキュリティスキャン
make security

# コスト見積もり
make cost ENV=prod

# ドキュメント生成
make docs

# リソース一覧
make state-list ENV=dev

# リソース詳細
make state-show ENV=dev RESOURCE=module.vpc.aws_vpc.main

# 環境間の差分
make diff-env FROM=dev TO=prod

# ステートバックアップ
make state-backup ENV=prod

# デバッグ情報
make debug ENV=dev
```

### 複数環境操作

```bash
# 全環境を初期化
make init-all

# 全環境でplan
make plan-all

# 全環境で検証
make validate-all
```

## 🔄 ワークフロー

### 開発フロー

```bash
# 1. 機能ブランチ作成
git checkout -b feature/new-feature

# 2. Terraformコード編集
vim terraform/modules/vpc/main.tf

# 3. 開発環境でテスト
make plan ENV=dev
make apply ENV=dev

# 4. 動作確認
make output ENV=dev

# 5. PR作成
git push origin feature/new-feature
```

### リリースフロー

```
develop → stg → prod

1. develop ブランチにマージ
   → 自動的にdev環境にデプロイ

2. main ブランチにマージ
   → 自動的にstg環境にデプロイ
   → 手動承認後、prod環境にデプロイ
```

## 🛡️ セキュリティ

### 機密情報の管理

```hcl
# ❌ 悪い例: tfvarsに直接記載
db_password = "super-secret-password"

# ✅ 良い例: Secrets Managerから取得
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "${var.environment}/rds/master-password"
}
```

### IAMロールの分離

各環境で異なるIAMロールを使用：

```yaml
# .github/workflows/terraform.yml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_dev }}  # 環境別
```

### ステートファイルの保護

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket  = "myapp-terraform-state"
    key     = "prod/terraform.tfstate"  # 環境別キー
    encrypt = true                      # 暗号化必須
    dynamodb_table = "terraform-state-lock"  # ロック
  }
}
```

## 🔍 トラブルシューティング

### ステートロックの解除

```bash
# ロックID確認
cd environments/prod
terraform force-unlock <LOCK_ID>
```

### ステートの確認

```bash
# リソース一覧
make state-list ENV=prod

# 特定リソース詳細
make state-show ENV=prod RESOURCE=module.vpc.aws_vpc.main

# ステート全体のダウンロード
cd environments/prod
terraform state pull > state-backup.json
```

### 環境間の差分確認

```bash
# 設定ファイルの差分
make diff-env FROM=dev TO=prod

# 実際のリソース差分（plan比較）
make plan ENV=dev > dev-plan.txt
make plan ENV=prod > prod-plan.txt
diff dev-plan.txt prod-plan.txt
```

### モジュールの依存関係確認

```bash
# グラフ生成（Graphviz必要）
make graph ENV=prod
# → prod-graph.png が生成される
```

## 📊 コスト管理

### 見積もり

```bash
# 特定環境のコスト
make cost ENV=prod

# 全環境のコスト比較
for env in dev stg prod; do
  echo "=== $env ==="
  make cost ENV=$env
done
```

### コスト削減のポイント

1. **開発環境**
   - Fargate Spot使用
   - 1つのNAT Gateway
   - 小さいインスタンスサイズ

2. **ステージング環境**
   - 本番より小さいリソース
   - 夜間・週末は停止可能

3. **本番環境**
   - Savings Plans検討
   - 予約インスタンス
   - オートスケーリング

## 🧪 テスト

### モジュールテスト

```bash
# 全モジュールの検証
make test-modules

# 特定モジュールのテスト
cd modules/vpc
terraform init
terraform validate
terraform plan
```

### セキュリティテスト

```bash
# tfsecでスキャン
make security

# または直接実行
tfsec terraform/
```

## 📚 ドキュメント

### 自動生成

```bash
# 全モジュールのREADME生成
make docs
```

### マニュアル確認

- [BEST_PRACTICES.md](BEST_PRACTICES.md) - ベストプラクティス
- [ENVIRONMENT_COMPARISON.md](ENVIRONMENT_COMPARISON.md) - 環境比較表
- 各モジュールの `README.md`

## 🚨 本番デプロイの注意点

### チェックリスト

- [ ] PRレビュー完了
- [ ] ステージング環境で動作確認
- [ ] バックアップ取得
- [ ] メンテナンス通知（必要な場合）
- [ ] ロールバック手順確認
- [ ] 監視アラート確認

### 本番デプロイ手順

```bash
# 1. プラン確認（必須）
make plan ENV=prod

# 2. チーム承認後、適用
make apply ENV=prod
# → 確認プロンプトで "yes" を入力

# 3. デプロイ後確認
make output ENV=prod

# 4. 動作確認
curl https://app.example.com/health

# 5. 監視確認
# CloudWatch、ALBメトリクスを確認
```

### ロールバック

```bash
# 前回のステートに戻す
cd environments/prod
terraform state pull > current-state.json
# バックアップから復元
terraform state push backup-state.json

# または、前回のコミットに戻してapply
git revert <commit>
make apply ENV=prod
```

## 🔗 関連リンク

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## 📝 ライセンス

MIT
