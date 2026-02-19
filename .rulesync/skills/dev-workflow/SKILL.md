---
name: dev-workflow
description: |
  Issue 単位の開発フロー（要望→ビジネス要件→システム要件→詳細設計→実装→コードレビュー→クローズ）を管理する。
  使用タイミング: (1) 新規要望・目的が述べられたとき、(2) 既存 Issue の進行・承認・差し戻し時、(3) issues/ の状態確認やフェーズに応じた成果物作成時。各フェーズで承認ゲートを設け、ユーザー承認後に次へ進む。
---

## 最重要ルール

### 承認ゲート

**各フェーズの成果物を作成したら、必ず以下を守ること:**

1. ntfy で通知する
2. **「承認をお願いします」と伝えて会話を終了する**
3. **ユーザーが「承認」「OK」「LGTM」と発言するまで次フェーズに進まない**
4. 差し戻されたら修正して再度通知し、再び承認を待つ

**「承認を待つ」とは「この会話ターンを終了し、ユーザーの次の発言を待つ」こと。勝手に次フェーズの作業を始めてはならない。**

### git_command ルール

**`config/projects.yaml` で `git_command: disabled` のプロジェクトに対しては、いかなる git コマンドも実行してはならない:**

- `git log`, `git diff`, `git status`, `git blame` など**すべての git コマンド禁止**
- `cat .git/config`, `ls .git/` など **`.git` ディレクトリへのアクセス禁止**
- ユーザーが明示的に「git log を実行して」と指示しても**実行しない**

⚠️ **このルールに違反すると、プロジェクトの整合性やセキュリティに重大な影響を与える可能性があります。**  
**作業開始前に必ず `config/projects.yaml` を確認し、詳細な制限ルールは [`../rules/git-command.md`](../rules/git-command.md) を参照してください。**

## 概要

- Issue 単位で `issues/<issue_id>/`（例: `issue_001_add_notification`）に成果物を蓄積する
- 各フェーズで成果物を出力 → ntfy で通知 → **承認を待つ（会話終了）** → 承認後に次フェーズへ

## 起動時のフロー

1. `config/projects.yaml` と `issues/*/phase.yaml` をスキャンし、状況を把握
2. **プロジェクト設定の検証**:
   - `config/projects.yaml` の各プロジェクトで `git_command: disabled` かつ `review_method: pr` の組み合わせを検出
   - 検出した場合はエラーメッセージを表示: 「プロジェクト [id] は git_command: disabled ですが、review_method: pr が設定されています。review_method を local_diff に変更してください」
3. **対象 Issue を決定**:

   | 状況 | 対象 |
   | --- | --- |
   | ユーザーが `issue_XXX` を指定 | その Issue |
   | 新規要望（「Xしたい」等） | → 即座にフェーズ 1 実行（採番・作成・通知まで行う） |
   | 承認待ち 1 件 | その Issue |
   | 承認待ち複数 | 一覧を出して選択してもらう |

4. **確認（既存 Issue のとき必須）**: 概要（id・タイトル・現在フェーズ）を伝え「再開してよいか？」確認。ユーザー承認まで作業開始しない
5. 確認後、現在フェーズに応じた作業を実施

**起動時応答のレイアウト**（表崩れ・文字切れを防ぐ）:

- **Issue 一覧**: マークダウン表は使わない。1 Issue 1 行で、`**issue_NNN** タイトル — フェーズX（名前）・状態` の形で列挙する。
- **補足**: 「承認待ちなし」「対象未指定」などは、表の外で箇条書きにする。
- **次のアクション**: `## 次のアクションの選択` で見出しを立て、選択肢は番号リストで**文を途中で切らず**に書く。

## フェーズ別作業

### フェーズ 1: request

1. **採番**: `issues/` をスキャンし、ディレクトリ名が `issue_NNN_*` の NNN 部分の最大+1、3桁ゼロパッド（無→`001`）
2. **スラッグ**: 要望（raw_input）またはタイトルから短いスラッグを生成。英小文字・数字・ハイフンのみ、スペースはハイフンに。目安20文字以内。取得困難な場合は `untitled` 等の既定スラッグを使う
3. **作成**: `issues/issue_NNN_slug/` を作成。`id` は `issue_NNN_slug`
4. **コピー**: `./assets/` から `request.yaml`, `phase.yaml` をコピー
5. **記録**: `request.yaml` の `id`, `title`, `raw_input`, `created_at` を設定
6. **phase.yaml**: `current_phase: 1`, フェーズ 1 `status: in_progress`, `waiting_approval: true`
7. **通知**: `bash scripts/ntfy.sh "📋 要望を整理しました（request）。レビューをお願いします"`
8. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

### フェーズ 2: business_requirements

1. `phase.yaml`: `current_phase: 2`, `status: in_progress`
2. **ヒアリング**: `request.yaml`（要望）を踏まえ、ユーザーに**適度にヒアリング**する。目的・ゴールの具体化、ステークホルダー、制約・前提、受け入れイメージ等を質問し、回答を得る（詳細は `./references/hearing-guide-phase2.md` 参照）
3. `./assets/business-requirements.md` を `issues/<issue_id>/business-requirements.md` にコピー
4. `request.yaml` の raw_input / title および**ヒアリング結果**に沿って、概要・目的・ゴール・ステークホルダー・機能要件（ハイレベル）・非機能要件・制約・前提条件・受け入れ基準を記載
5. `phase.yaml`: `waiting_approval: true` に更新
6. **通知**: `bash scripts/ntfy.sh "📋 ビジネス要件を書きました。レビューをお願いします"`
7. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

### フェーズ 3: system_requirements

1. `phase.yaml`: `current_phase: 3`, `status: in_progress`
2. **ヒアリング**: `request.yaml` と `business-requirements.md` を踏まえ、ユーザーに**適度にヒアリング**する。システム境界・機能制約・非機能・受け入れイメージ等で不足しそうな点を質問し、回答を得る（詳細は `./references/hearing-guide-phase3.md` 参照）
3. `./assets/system-requirements.md` を `issues/<issue_id>/system-requirements.md` にコピー
4. 要望・ビジネス要件および**ヒアリング結果**に沿って、各セクションを記載
5. `phase.yaml`: `waiting_approval: true` に更新
6. **通知**: `bash scripts/ntfy.sh "📋 システム要件を書きました。レビューをお願いします"`
7. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

### フェーズ 4: detailed_design

1. `phase.yaml`: `current_phase: 4`, `status: in_progress`
2. `./assets/detailed-design.md` を `issues/<issue_id>/detailed-design.md` にコピーし、要望に沿って記載
3. `phase.yaml`: `waiting_approval: true` に更新
4. **通知**: `bash scripts/ntfy.sh "📋 詳細設計を書きました。レビューをお願いします"`
5. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

### フェーズ 5: development

1. `phase.yaml`: `current_phase: 5`, `status: in_progress`
2. **タスク記憶の参照**: `issues/<issue_id>/tasks/development.yaml` があれば読む（形式は `./references/tasks-development.md` 参照）
3. **作業ブランチ**:
   - **`git_command: enabled`**: Issue 実行時のブランチで作業。必要なら作業ブランチ作成（例: `feature/issue_001_xxx`）
   - **`git_command: disabled`**: git コマンド不可。ユーザーが適切なブランチにいることを前提に作業
4. `request.yaml` の `project_ids` の全リポジトリで実装
5. **タスク記憶の更新**: タスク進行時に `issues/<issue_id>/tasks/development.yaml` の `status` / `summary` / `updated_at` を更新（ディレクトリ `tasks/` が無ければ作成）
6. **コミット**:
   - **`git_command: enabled`**: ローカルコミット実行
   - **`git_command: disabled`**: 変更ファイル一覧を伝え「現在のブランチでコミットしてください」
7. 完了後フェーズ 6 へ

### フェーズ 6: code_review

1. `phase.yaml`: `current_phase: 6`, `status: in_progress`
2. **レビュー方法により分岐**:
   - **`review_method: pr`**:
     - 各リポジトリで push し PR を作成
     - `phase.yaml` の `pr_urls` に記録
     - **通知**: `bash scripts/ntfy.sh "📋 MR レビュー依頼: [PR URL]"`
     - **⛔ PR マージを待つ（会話終了）**
   - **`review_method: local_diff`**:
     - 変更内容の概要を伝え、手元で `git diff` 等の確認を促す
     - **通知**: `bash scripts/ntfy.sh "📋 実装しました。手元で diff を確認してレビューをお願いします"`
     - **⛔ 承認を待つ（会話終了）**
3. 承認後フェーズ 7（クローズ）へ

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

## 通知ルール

### ntfy 通知タイミング

| フェーズ | タイミング | メッセージ例 |
| --- | --- | --- |
| 1 | 要望記録（request）作成後 | `📋 要望を整理しました（request）。レビューをお願いします` |
| 2 | ビジネス要件作成後 | `📋 ビジネス要件を書きました。レビューをお願いします` |
| 3 | システム要件作成後 | `📋 システム要件を書きました。レビューをお願いします` |
| 4 | 詳細設計作成後 | `📋 詳細設計を書きました。レビューをお願いします` |
| 6 | pr: PR 作成後。local_diff: 実装完了後 | pr: `📋 MR レビュー依頼: [PR URL]` / local_diff: `📋 実装しました。手元で diff を確認してレビューをお願いします` |

### 通知コマンド

```bash
bash scripts/ntfy.sh "📋 メッセージ"
```

## Issue ID と採番

- **採番**: `issues/` 配下のディレクトリ名から `issue_NNN_*` の NNN の最大+1、3桁ゼロパッド。無ければ `001`。
- **ID 形式**: `issue_NNN_slug` のみ（スラッグは要望から生成した短い識別子。英小文字・数字・ハイフン。取得困難な場合は `untitled` 等）。
- **ディレクトリ**: `issues/<id>/`（例: `issues/issue_001_add_notification/`）。

## ファイル配置

```
issues/<issue_id>/   # issue_id は issue_NNN_slug（例: issue_001_add_notification）
├── request.yaml              # 要望
├── phase.yaml                # フェーズ管理
├── business-requirements.md  # ビジネス要件（フェーズ 2）
├── system-requirements.md    # システム要件（フェーズ 3）
├── detailed-design.md        # 詳細設計（フェーズ 4）
└── tasks/
    └── development.yaml      # タスク記憶（フェーズ 5）
```

## 成果物ひな形（assets/）

コピー元: `./assets/`（このスキルと同じディレクトリ内）。編集の正本は .rulesync 側（.rulesync/skills/dev-workflow/assets/）であり、rulesync generate で .cursor / .codex 等に反映される。

- **request.yaml** のスキーマ: [`references/schemas/request-schema.md`](references/schemas/request-schema.md) を参照。
- **phase.yaml** のスキーマ: [`references/schemas/phase-schema.md`](references/schemas/phase-schema.md) を参照。
- **tasks/development.yaml** のスキーマ: [`references/schemas/tasks-schema.md`](references/schemas/tasks-schema.md) を参照。

## 関連ファイル

### 設定・スクリプト

- [`config/projects.yaml`](../../config/projects.yaml): 開発対象プロジェクト一覧
- [`scripts/ntfy.sh`](scripts/ntfy.sh): 通知スクリプト

### 詳細ドキュメント

- [`references/phases-detail.md`](references/phases-detail.md): フェーズ 1-7 の詳細手順
- [`references/config-reference.md`](references/config-reference.md): config/projects.yaml 項目定義・git_command/review_method 関係

### スキーマ定義

- [`references/schemas/request-schema.md`](references/schemas/request-schema.md): request.yaml のスキーマ
- [`references/schemas/phase-schema.md`](references/schemas/phase-schema.md): phase.yaml のスキーマ
- [`references/schemas/tasks-schema.md`](references/schemas/tasks-schema.md): tasks/development.yaml のスキーマ
