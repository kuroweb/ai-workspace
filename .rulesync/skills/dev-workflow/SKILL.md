---
name: dev-workflow
description: |
  Issue 単位の開発フロー（要望→ビジネス要件→システム要件→詳細設計→実装→コードレビュー→クローズ）を管理する。デプロイは各プロダクトの CI/CD に委ねる。
  使用タイミング: (1) 新規要望・目的を述べたときは**まず issue_NNN_slug と request.yaml / phase.yaml を生成し、ユーザー承認を得てから**次フェーズへ進む、(2) 承認待ちの Issue を進めるとき、(3) 「承認」「差し戻し」と発言したとき、(4) issues/ の状態確認やフェーズに応じた成果物作成・PR 作成を行うとき。
---

## 最重要ルール: 承認ゲート

**各フェーズの成果物を作成したら、必ず以下を守ること:**

1. ntfy で通知する
2. **「承認をお願いします」と伝えて会話を終了する**
3. **ユーザーが「承認」「OK」「LGTM」と発言するまで次フェーズに進まない**
4. 差し戻されたら修正して再度通知し、再び承認を待つ

**「承認を待つ」とは「この会話ターンを終了し、ユーザーの次の発言を待つ」こと。勝手に次フェーズの作業を始めてはならない。**

---

詳細なフェーズ定義・承認パターン・差し戻しパターンは `./references/flow.md` を参照。

## 概要

- Issue 単位で `issues/<issue_id>/`（例: `issue_001_add_notification`）に成果物を蓄積する
- 各フェーズで成果物を出力 → ntfy で通知 → **承認を待つ（会話終了）** → 承認後に次フェーズへ

## 起動時にやること

1. `config/projects.yaml` と `issues/*/phase.yaml` をスキャンし、状況を把握
2. **対象 Issue を決定**:

   | 状況 | 対象 |
   | --- | --- |
   | ユーザーが `issue_XXX` を指定 | その Issue |
   | 新規要望（「Xしたい」等） | → 即座にフェーズ 1 実行（採番・作成・通知まで行う） |
   | 承認待ち 1 件 | その Issue |
   | 承認待ち複数 | 一覧を出して選択してもらう |

3. **確認（既存 Issue のとき必須）**: 概要（id・タイトル・現在フェーズ）を伝え「再開してよいか？」確認。ユーザー承認まで作業開始しない
4. 確認後、現在フェーズに応じた作業を実施

**起動時応答のレイアウト**（表崩れ・文字切れを防ぐ）:

- **Issue 一覧**: マークダウン表は使わない。1 Issue 1 行で、`**issue_NNN** タイトル — フェーズX（名前）・状態` の形で列挙する。
- **補足**: 「承認待ちなし」「対象未指定」などは、表の外で箇条書きにする。
- **次のアクション**: `## 次のアクションの選択` で見出しを立て、選択肢は番号リストで**文を途中で切らず**に書く。

## 各フェーズの作業

### フェーズ 1: request

**⛔ 該当 Issue が見つからないときは必ず以下を実行すること。説明だけして「Issue を作成しましょうか？」などと聞いて終えてはならない。**

1. **採番**: `issues/` をスキャンし、ディレクトリ名が `issue_NNN_*` の NNN 部分の最大+1、3桁ゼロパッド（無→`001`）
2. **スラッグ**: 要望（raw_input）またはタイトルから短いスラッグを生成。英小文字・数字・ハイフンのみ、スペースはハイフンに。目安20文字以内。取得困難な場合は `untitled` 等の既定スラッグを使う
3. **作成**: `issues/issue_NNN_slug/` を作成。`id` は `issue_NNN_slug`
4. **コピー**: `./assets/` から `request.yaml`, `phase.yaml` をコピー
5. **記録**: `request.yaml` の `id`, `title`, `raw_input`, `created_at` を設定
6. **phase.yaml**: `current_phase: 1`, フェーズ 1 `status: in_progress`, `waiting_approval: true`
7. **通知**: `bash scripts/ntfy.sh "📋 要望を整理しました（request）。レビューをお願いします"`
8. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

### フェーズ 2: business_requirements

1. **ヒアリング**: フェーズ 2 開始時、`request.yaml`（要望）を踏まえ、ユーザーに**適度にヒアリング**する。目的・ゴールの具体化、ステークホルダー、制約・前提、受け入れイメージ等を質問し、回答を得る。詳細は `./references/hearing-guide-phase2.md` を参照。
2. **コピー**: このスキルと同じディレクトリの `./assets/business-requirements.md` を `issues/<issue_id>/business-requirements.md` にコピーする。（`<issue_id>` は当該 Issue の id。例: `issue_001_add_notification`）（編集正本は .rulesync のため、.rulesync/skills/dev-workflow/assets/ を編集すると rulesync generate で .cursor / .codex 等に反映される。）
3. **記載**: `request.yaml` の raw_input / title および**ヒアリング結果**に沿って、概要・目的・ゴール・ステークホルダー・機能要件（ハイレベル）・非機能要件・制約・前提条件・受け入れ基準を埋める。
4. **phase.yaml**: `current_phase: 2`, フェーズ 2 `status: in_progress`, `waiting_approval: true` に更新する。
5. **通知**: `bash scripts/ntfy.sh "📋 ビジネス要件を書きました。レビューをお願いします"`
6. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

### フェーズ 3: system_requirements

1. **ヒアリング**: フェーズ 3 開始時、`request.yaml` と `business-requirements.md` を踏まえ、ユーザーに**適度にヒアリング**する。システム境界・機能制約・非機能・受け入れイメージ等で不足しそうな点を質問し、回答を得る。詳細は `./references/hearing-guide-phase3.md` を参照。
2. **コピー**: `./assets/system-requirements.md` を `issues/<issue_id>/system-requirements.md` にコピーする。
3. **記載**: 要望・ビジネス要件および**ヒアリング結果**に沿って、各セクションを埋める。
4. **phase.yaml**: `current_phase: 3`, フェーズ 3 `status: in_progress`, `waiting_approval: true` に更新する。
5. **通知**: `bash scripts/ntfy.sh "📋 システム要件を書きました。レビューをお願いします"`
6. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

### フェーズ 4: detailed_design

1. assets から `detailed-design.md` をコピーし、要望に沿って記載
2. `phase.yaml`: `current_phase: 4`, `waiting_approval: true`, `status: in_progress`
3. **通知**: `bash scripts/ntfy.sh "📋 詳細設計を書きました。レビューをお願いします"`
4. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

### フェーズ 5: development

1. `phase.yaml`: `current_phase: 5`, `status: in_progress`
2. **タスク記憶の参照**: 対象 Issue の `issues/<issue_id>/tasks/development.yaml` があれば読み、現在のタスク一覧を把握する。形式は `./references/tasks-development.md` を参照。
3. `request.yaml` の `project_ids` の全リポジトリで実装
4. **タスク記憶の更新**: タスクを進めたら、`issues/<issue_id>/tasks/development.yaml` に「追加」または既存エントリの `status` / `summary` / `updated_at` を更新する。ディレクトリ `tasks/` が無ければ作成する。
5. ローカルコミット（PR はまだ作らない）。タスク記憶ファイルもコミット対象に含める（推奨）。
6. 完了したら `status: completed` にしてフェーズ 6 へ（承認不要）

### フェーズ 6: code_review

プロジェクトによっては AI の git 操作が禁止されているため、レビュー方法を **PR** と **手元の diff** のどちらかで実施する。`config/projects.yaml` の各プロジェクトで `review_method` を必須で記述する。

- **PR（review_method: pr）**
  1. AI が各リポジトリで push し PR を作成
  2. `phase.yaml` の `pr_urls` に PR URL を記録
  3. **通知**: 各 PR URL を `bash scripts/ntfy.sh "📋 MR レビュー依頼: [PR URL]"` で通知
  4. **⛔ PR マージを待つ — ここで会話を終了。マージ後にユーザーが報告するまで待つ**
- **手元の diff（review_method: local_diff）**
  1. AI は git push / PR 作成を行わない。変更内容の概要（対象ファイル・差分の要点）を伝え、ユーザーに手元で `git diff` 等の確認を促す
  2. **通知**: `bash scripts/ntfy.sh "📋 実装しました。手元で diff を確認してレビューをお願いします"`
  3. **⛔ 承認を待つ — ここで会話を終了。ユーザーが手元で確認し「承認」と発言するまで待つ**
  4. 承認されたらフェーズ 6 を `completed` にしてフェーズ 7（クローズ）へ。`pr_urls` は使わない

### フェーズ 7: close

1. フェーズ 6 が完了したタイミングで、`phase.yaml` の全フェーズを `completed` にして Issue をクローズする。

## 承認時の動作

ユーザーが「承認」「OK」「LGTM」と発言したら:

1. `phase.yaml`: `waiting_approval: false`, 該当フェーズ `status: completed`, `current_phase` +1
2. 次フェーズの作業を開始

## 差し戻し時の動作

ユーザーが「差し戻し: [理由]」と発言したら:

1. `phase.yaml`: `waiting_approval: false`, `status: rejected`, `rejection_reason` に理由を記録
2. 成果物を修正
3. 再通知し、`waiting_approval: true` に戻す
4. **⛔ 再び承認を待つ — 会話を終了**

詳細は `./references/flow.md` 参照。

## Issue ID と採番

- **採番**: `issues/` 配下のディレクトリ名から `issue_NNN_*` の NNN の最大+1、3桁ゼロパッド。無ければ `001`。
- **ID 形式**: `issue_NNN_slug` のみ（スラッグは要望から生成した短い識別子。英小文字・数字・ハイフン。取得困難な場合は `untitled` 等）。
- **ディレクトリ**: `issues/<id>/`（例: `issues/issue_001_add_notification/`）。

## 成果物ひな形（assets/）

コピー元: `./assets/`（このスキルと同じディレクトリ内）。編集の正本は .rulesync 側（.rulesync/skills/dev-workflow/assets/）であり、rulesync generate で .cursor / .codex 等に反映される。

- **request.yaml** のスキーマ: `./references/request-schema.md` を参照。
- **phase.yaml** のスキーマ: `./references/phase-schema.md` を参照。

## 関連ファイル

- `config/projects.yaml`: 開発対象プロジェクト一覧（各プロジェクトの項目・`review_method` の意味は `./references/flow.md` の「config/projects.yaml の項目」を参照）
- `scripts/ntfy.sh`: 通知スクリプト
- `./references/flow.md`: フェーズ定義・承認・差し戻しルール詳細
- `./references/request-schema.md`: request.yaml のスキーマ
- `./references/phase-schema.md`: phase.yaml のスキーマ
