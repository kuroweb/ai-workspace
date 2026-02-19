# request.yaml のスキーマ

Issue の要望を記録するファイル。フェーズ 1 で AI が作成・記入する。以下のルールを守ること。

| フィールド | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `id` | string | ○ | Issue 識別子。`issue_NNN_slug` 形式（NNN は 3 桁ゼロパッド、slug は要望から生成したスラッグ）。採番は `issues/` のディレクトリ名から最大番号+1。 |
| `project_ids` | array of string | ○ | この Issue で扱うリポジトリ。`config/projects.yaml` の `projects[].id` と一致すること。実装・PR は列挙したすべてで行う。空配列可（後で確定する場合）。 |
| `title` | string | ○ | Issue のタイトル。要望を一言で表す。 |
| `created_at` | string | ○ | 作成日時。ISO 8601 形式（例: `2026-02-14T10:30:00+09:00`）。 |
| `raw_input` | string | ○ | ユーザーの要望をそのまま記載。フェーズ 2 のヒアリングとビジネス要件の元。複数行可（`\|` でブロック）。 |
| `review_method` | string | ○ | フェーズ 6 のレビュー方法。`pr` または `local_diff`。デフォルト: `local_diff`。 |

- 上記以外のキーを追加する場合は、このスキーマ説明を更新すること。
