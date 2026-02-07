# 環境別設定比較表

## リソース設定の比較

| 項目 | Production | Staging | Development |
|------|-----------|---------|-------------|
| **VPC CIDR** | 10.0.0.0/16 | 10.1.0.0/16 | 10.10.0.0/16 |
| **Availability Zones** | 3 | 2 | 2 |
| **NAT Gateway数** | 3 (高可用性) | 1 (コスト削減) | 1 (コスト削減) |
| **ECS CPU** | 1024 | 512 | 256 |
| **ECS Memory** | 2048 MB | 1024 MB | 512 MB |
| **ECS Desired Count** | 3 | 2 | 1 |
| **Auto Scaling** | 有効 (3-10) | 有効 (2-4) | 無効 |
| **Container Insights** | 有効 | 無効 | 無効 |
| **HTTPS** | 有効 | 有効 | 無効 |
| **WAF** | 有効 | 無効 | 無効 |
| **ALB Access Logs** | 有効 | 無効 | 無効 |
| **CloudWatch Logs保持期間** | 30日 | 14日 | 7日 |
| **Deletion Protection** | 有効 | 無効 | 無効 |
| **バックアップ保持期間** | 30日 | 14日 | 7日 |
| **Multi-AZ** | 有効 | 無効 | 無効 |
| **監視アラート** | 詳細 | 基本 | なし |

## 環境変数の違い

### Production
```
NODE_ENV=production
LOG_LEVEL=info
API_ENDPOINT=https://api.example.com
```

### Staging
```
NODE_ENV=staging
LOG_LEVEL=info
API_ENDPOINT=https://api-stg.example.com
```

### Development
```
NODE_ENV=development
LOG_LEVEL=debug
API_ENDPOINT=https://api-dev.example.com
```

## URL構成

| 環境 | URL | SSL証明書 |
|------|-----|----------|
| Production | https://app.example.com | ACM証明書 |
| Staging | https://stg.example.com | ACM証明書 |
| Development | http://{alb-dns-name} | なし |

## コスト見積もり（月額）

### Production
- ECS Fargate (1024 CPU, 2048 MB) x 3タスク: ~$90
- NAT Gateway x 3: ~$100
- ALB: ~$25
- CloudWatch Logs: ~$10
- その他: ~$25
- **合計: 約$250/月**

### Staging
- ECS Fargate (512 CPU, 1024 MB) x 2タスク: ~$30
- NAT Gateway x 1: ~$35
- ALB: ~$25
- CloudWatch Logs: ~$5
- その他: ~$10
- **合計: 約$105/月**

### Development
- ECS Fargate Spot (256 CPU, 512 MB) x 1タスク: ~$5
- NAT Gateway x 1: ~$35
- ALB: ~$25
- CloudWatch Logs: ~$2
- その他: ~$5
- **合計: 約$72/月**

## デプロイ戦略

### Production
- デプロイ: mainブランチのみ
- 承認: 必須（手動承認）
- タイミング: 営業時間外
- ロールバック: 自動

### Staging
- デプロイ: developブランチから自動
- 承認: 不要
- タイミング: 任意
- ロールバック: 手動

### Development
- デプロイ: 全ブランチから自動
- 承認: 不要
- タイミング: 任意
- ロールバック: 手動

## セキュリティ設定

### Production
- IAMロール制限: 最小権限
- ネットワーク: プライベートサブネットのみ
- WAF: 有効（レート制限、SQL injection対策）
- Secrets管理: Secrets Manager
- 監査ログ: CloudTrail有効
- 脆弱性スキャン: 有効

### Staging
- IAMロール制限: 中程度
- ネットワーク: プライベートサブネットのみ
- WAF: 無効
- Secrets管理: Secrets Manager
- 監査ログ: 基本のみ
- 脆弱性スキャン: 有効

### Development
- IAMロール制限: 緩め（開発用）
- ネットワーク: プライベートサブネットのみ
- WAF: 無効
- Secrets管理: 環境変数
- 監査ログ: なし
- 脆弱性スキャン: 無効

## バックアップとDR

### Production
- データベースバックアップ: 日次、保持30日
- スナップショット: 自動、保持7日
- クロスリージョンレプリケーション: 検討
- RTO: 1時間
- RPO: 5分

### Staging
- データベースバックアップ: 日次、保持14日
- スナップショット: 自動、保持3日
- クロスリージョンレプリケーション: なし
- RTO: 4時間
- RPO: 1時間

### Development
- データベースバックアップ: 日次、保持7日
- スナップショット: 手動
- クロスリージョンレプリケーション: なし
- RTO: ベストエフォート
- RPO: ベストエフォート
