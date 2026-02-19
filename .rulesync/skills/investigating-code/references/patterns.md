# レポートパターン集

調査タイプ別のレポートテンプレート。状況に応じて適切なパターンを選択する。

## パターン1: テーブル移行に伴うレガシーAPIの調査

テーブルスキーマ変更に伴う旧APIのアクセス状況調査、デッドコードの特定と撤去方針の策定。

```markdown
# 目的

- [#1234 Legacy API endpoint investigation](チケットシステムへのリンク)
- 新方式データベーススキーマ対応のため、旧API（`/api/v1/legacy/add`）の調査と対応方針の策定

# 調査ログ

## アクセス状況を調査

- アクセスログ分析

    ```sql
    SELECT
      DATE(timestamp) AS date,
      user_agent,
      endpoint,
      COUNT(*) AS access_count
    FROM
      access_logs
    WHERE
      timestamp BETWEEN '2026-01-01' AND '2026-01-10'
      AND endpoint LIKE '%/api/v1/legacy/add%'
    GROUP BY
      date,
      user_agent,
      endpoint
    ORDER BY
      date ASC,
      access_count DESC
    ```

    結果: 10日間で11件のアクセス

**対応方針:**

- 👉若干数のアクセスはあるが撤去可能かもしれない
- 👉撤去よりもコード修正の方が現実的（アナウンス調整や古いクライアントでの挙動調査で時間がかかる）

## `/api/v1/legacy/add` について

- [src/controllers/api/legacy_controller.rb#L88-101](リポジトリへのリンク)
- `/api/v1/legacy/add` では`プロモコード適用のパラメータ`は存在しない
- 内部的なプロモコード自動適用の仕組みはあるが、ほぼデッドコードと思われる
  - [src/services/cart_service.rb#L204](リポジトリへのリンク)

**対応方針:**

- 👉`SELECT, UPDATE`の向け先テーブルを新方式に切り替えるだけで良さそう

## プロモコード自動適用の仕組みがある

- 以下のチケットで実装された機能
  - 過去のチケット#567
- ABテスト用のプロモコードがあるらしい
- いずれのプロモコードも`2019年期限` だったので不要な仕組みだと思われる

    ```sql
    SELECT
      code_id,
      code,
      expiry_date,
      status,
      description
    FROM
      promo_codes
    WHERE
      code_id IN (1001, 1002, 1003, ...)
      AND expiry_date < CURRENT_DATE
    ```

    結果: すべて期限切れ

**対応方針:**

- 👉自動適用の仕組みは実質的にデッドコードなので撤去する

## 対応方針まとめ

- デッドコードを撤去する
  - `プロモコード自動適用の仕組み`を撤去
  - `user_cart.promo_code`への`UPDATE・INSERT`を撤去
  - `user_cart.promo_code` への`SELECT`を撤去
- カート機能におけるプロモコード情報を参照する必要がなくなるので、新方式のテーブル（`cart_promos`）へのSELECTなどは発生しない想定
```

## パターン2: テーブル移行に伴う対応要否調査

テーブルスキーマ変更に伴う既存コード（JOIN処理等）への影響調査と対応要否の判断。

```markdown
# 目的

- [#5678 テーブル移行に伴うJOIN処理の影響調査](チケットシステムへのリンク)

# 調査ログ

## calculateUserSummary メソッド

- 👉対応不要だった
- ソースコード
  - [src/services/report_service.rb#L153](リポジトリへのリンク)
- メソッドの役割
  - ユーザーの集計データを計算している
  - `table_a → table_b` でJOINしているが現状のままでも動作に問題なし
- 動作テスト
  - 管理画面の`レポート > 詳細`にアクセスして、集計値を正しく表示できていることを確認
  - テスト環境URL: https://admin.test.example.com/reports/123
    <img width="500" alt="動作確認スクリーンショット" src="...">

## getDataList メソッド

- 👉対応不要だった
- ソースコード
  - [src/services/report_service.rb#L266](リポジトリへのリンク)
- メソッドの役割
  - 一覧表示に必要なデータとして、関連情報を抽出している
  - `table_a → table_b` でJOINしているが現状のままでも動作に問題なし
- 動作テスト
  - 管理画面の`データ管理`にアクセスして正しくリスト表示を確認
  - テスト環境URL: https://admin.test.example.com/data
    <img width="500" alt="動作確認スクリーンショット" src="...">

## 対応方針まとめ

- すべてのメソッドで`table_a → table_b` のJOINは現状のままで動作に問題なし
- 👉一部のメソッドで無駄なJOINとなっているが、パフォーマンス影響は軽微なため優先度は低い
```

## パターン3: エラー調査とリプレース方針検討

アプリケーションエラーの原因特定と段階的なリプレース方針の策定。

```markdown
# 目的

- [#9012 Multiple promo codes causing errors](チケットシステムへのリンク)

# 作業ログ

## 複数割引コード適用時に詳細画面でエラーになる

- 該当データ:
  - 管理画面: https://admin.test.example.com/orders/123456
- `Order → Discount` のアソシエーション定義が原因
  - [src/models/Order.java#L176-178](リポジトリへのリンク)

        ```java
        @ManyToOne(targetEntity = Discount.class, fetch = FetchType.LAZY)
        @JoinColumn(name = "order_id", referencedColumnName = "order_id", insertable = false, updatable = false)
        private Discount discount;
        ```

  - ORMは`Discount`が`1件`を期待するのに`2件以上` 返却されることで`More than one rowエラー`が生じている状態
- `フィールド参照（Order.discount）`と、`getter/setter参照（getDiscount, setDiscount）` でアソシエーションを利用しており、参照されたタイミングで例外をスローしてしまう
  - フィールド参照例：[src/models/Order.java#L262](リポジトリへのリンク)
- アソシエーション自体は`FetchType.LAZY` なのでOrderインスタンスが生成されるだけではエラーにならないが、参照メソッドが呼ばれた時点でエラーとなる
- 👉既存のアソシエーションを撤去するまでエラー解消は不可能

## リプレース方針

- アソシエーション定義を`Order.discount → Order.discounts` にリプレースする
- リプレース作業を段階的に実施する
  - `Order.discount` の参照箇所を個別に`Order.discounts`にリプレース
  - `Order.discount`の参照箇所がなくなったら撤去
- `Order.discount` を撤去するまで上述のエラーは解消できないので、テスト方法を妥協する
  - 複数割引コードデータではテストしない
  - 単一割引コードでテストする
  - `Order.discount` を撤去したら複数割引コードデータで再度テストする

**対応方針:**

- 👉段階的なリプレースにより安全に移行
- 👉テスト方法を現実的な範囲に調整
```

## パターン4: 運用フロー・設計ドキュメント

機能の運用フローや設計方針を詳細にまとめる大規模ドキュメント。

```markdown
# 目的

- [#3456 Pricing rule configuration](チケットシステムへのリンク)
- 価格ルールマスターファイルの運用フローを整理しておく

# 概要

- 以下の価格ルールマスターファイルに記述した内容が、動的価格設定のルールとして反映されます
  - [config/pricing_rules.yml](リポジトリへのリンク)

# 本番化手順

- `通常の本番化手順`で価格ルールマスターファイルの修正内容を本番化してください
- ⚠️YAMLの記述エラーによる本番影響も考えられるので、テスト環境で必ず動作確認すること

# YAMLファイルの記述方法

## 対象商品を指定する

- ⚠️各フィールドは省略せずに必ず記述してください（省略不可）

### カテゴリで絞り込み（`category_ids`）

- カテゴリIDを複数指定できる（`categories.id`）
  - 親カテゴリ、子カテゴリで指定可能

    ```yaml
    # 子カテゴリで指定した場合
    category_ids: [101, 102]
    
    # 親カテゴリで指定した場合
    category_ids: [10] # 配下のすべてのカテゴリを指定
    ```

- `カテゴリを指定しない場合`は`category_ids: []` と記述すること

## 既存の価格ルールを無効化する

- ⚠️**既存の価格ルールを削除しないでください**
- 不要になった価格ルールは`enabled: false` に変更して無効化すること（**厳守**）

    ```yaml
    - id: 1
      category_ids: [101]
      promo_rate: 10
      enabled: false # ✅true -> false に変更
    ```

## 価格ルールの優先順位

- 1つの商品に適用される価格ルールは`最大1つまで`
- 商品が複数の価格ルールにマッチする場合は、価格ルールマスターファイルの`記載順に優先`する仕様

    ```yaml
    - id: 1
      category_ids: [50]
      promo_rate: 10
      enabled: true
    
    - id: 2
      category_ids: [50]  # id: 1と重複するが、id: 1が優先される
      promo_rate: 15
      enabled: true
    ```

  - 👉`category_id: 50` の商品には、`id: 1`の価格ルール（10%割引）が適用される
```

## パターン5: バッチ処理調査

バッチ処理やデータ集計処理の調査と修正方針。

```markdown
# 目的

- [#7890 Daily sales aggregation batch](チケットシステムへのリンク)

# 作業ログ

## `generate_summary.rb` とは

- 売上集計バッチのこと
- `毎月1日の午前2時` にバッチ実行される
  - [config/cron/monthly_jobs.yml#L15](リポジトリへのリンク)

## `saveAggregateData` メソッド

- `配送完了`の注文データの集計結果を`data_summary` テーブルにインサートしている
  - [src/batch/generate_summary.rb#L80](リポジトリへのリンク)
- SELECT内容
  - `user_promo`: ユーザープロモコードの金額
  - `system_promo`: システムプロモコードの金額
  - `payment_amount`: 注文金額から利用プロモコードの金額を差し引いた金額

**対応方針:**

- 👉複数プロモコード適用した注文では、すべてのプロモコードの金額を差し引けるように要修正

## `data_summary` テーブルの利用目的と関係者

- 管理画面の`売上レポート`からダウンロードできるCSVファイルのローデータとして参照されている
- 主なステークホルダーは経理チームだが、過去に確認したところ誰も使ってない機能ということになり、月次レポート機能を停止したらしい
  - 過去の議論へのリンク
- しかし、`data_summary`を生成する`generate_summary.rb` はまだ動き続けている状況（== 無意味なデータ生成）
- 👉将来的に撤去予定とのことだが、不整合なクエリが残っていると煩わしいので修正しておく

## 対応方針

- 撤去予定の機能・テーブルだが、不整合なクエリを残したくないので修正しておく
  - `LEFT OUTER JOIN`ではなく、`条件付きのLEFT OUTER JOIN`に書き換える
  - `payment_amount` の計算で複数プロモコードの金額を減算できるようにする
```
