# phase.yaml のスキーマ

Issue のフェーズ管理ファイル。各フェーズで AI が `current_phase` / 各フェーズの `status` / `waiting_approval` を更新する。

## トップレベル

| フィールド | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `current_phase` | integer | ○ | 現在のフェーズ番号。1〜7。 |
| `waiting_approval` | boolean | ○ | 承認待ちかどうか。成果物提示後は `true`、承認/差し戻し後に `false`。 |
| `phases` | object | ○ | フェーズ番号をキーにした各フェーズの定義（下記）。 |

## phases の各フェーズ（1〜7）

各キー（`1` … `7`）はフェーズ番号。共通で以下を持つ。

| フィールド | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `name` | string | ○ | フェーズ名。1=request, 2=business_requirements, 3=system_requirements, 4=detailed_design, 5=development, 6=code_review, 7=close。 |
| `status` | string | ○ | いずれか: `pending`（未着手）, `in_progress`（作業中）, `completed`（完了）, `rejected`（差し戻し）。 |
| `rejection_reason` | string or null | - | 差し戻し時のみ。理由を記録。フェーズ 2〜4, 6 で使用。 |
| `output` | string | - | 成果物ファイル名。フェーズ 2=business-requirements.md, 3=system-requirements.md, 4=detailed-design.md。 |
| `pr_urls` | array of string | - | フェーズ 6 のみ。`project_ids` の順で各リポジトリの PR URL。review_method が pr の場合に記録。 |

## 更新ルール

- フェーズ開始時: 該当フェーズの `status: in_progress`, `waiting_approval: true`
- 承認時: `waiting_approval: false`, 該当フェーズ `status: completed`, `current_phase` を +1
- 差し戻し時: `waiting_approval: false`, 該当フェーズ `status: rejected`, `rejection_reason` に理由を記録
- フェーズ 7（close）: 全フェーズを `status: completed` にして Issue をクローズ

上記以外のキーを追加する場合は、このスキーマ説明を更新すること。
