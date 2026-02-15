# タスク記憶（development フェーズ）

フェーズ 5（development）で、作業内容を Issue ごとに保持するための形式。

## 配置

- **パス**: `issues/<issue_id>/tasks/development.yaml`（`issue_id` は当該 Issue の id。例: `issue_001_add_notification`）
- ディレクトリ `tasks/` が無ければ作成する。

## development.yaml の形式

- ルートは **YAML の配列**（タスクのリスト）。
- 各要素は次のキーを持つ。

| キー | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `id` | string | ○ | タスクの一意識別子 |
| `summary` | string | ○ | タスクの概要 |
| `status` | string | ○ | `pending` / `in_progress` / `completed` のいずれか |
| `updated_at` | string | ○ | 最終更新日時（ISO 8601 推奨） |
| `note` | string | - | 補足（任意） |

## 例

```yaml
- id: t1
  summary: 通知スクリプトの骨格を追加
  status: completed
  updated_at: "2026-02-15T10:00:00+09:00"
- id: t2
  summary: 設定からトピックを読む処理を実装
  status: in_progress
  updated_at: "2026-02-15T10:05:00+09:00"
  note: config/settings.yaml を参照
```
