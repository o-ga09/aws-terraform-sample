# Terraform With AWS

AWS環境をterraformで構築するサンプル

## 事前準備

1. terraformコマンドのインストール
2. terraformコマンドのインスール確認
3. terraformプロジェクトの初期化
    ```bash
    $ terraform init
    ```
4. インフラ構築
   ```bash
   $ terraform apply
   ```
5. インフア環境削除
   ```bash
   $ terraform destroy
   ```

## terraformコマンドの使い方

- `terraform init` : プロジェクトの初期化
- `terraform fmt` : terraformコードのフォーマット
- `terraform apply` : インフラ環境の構築
- `terraform destroy` : インフラ環境の削除
- `terraform validate` : terraformコードの妥当性確認
- `terraform show` : terraformコードの内容の一覧表示
- `terraform plan` : インフラに反映されるリソースの確認
- `terraform state list` : terraform管理されているリソースの状態の一覧表示

## デプロイ

## CI/CD

## 参考

https://developer.hashicorp.com/terraform

https://hi1280.hatenablog.com/entry/2023/04/07/200303
