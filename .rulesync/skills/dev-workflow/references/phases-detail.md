# フェーズ別作業の詳細

各フェーズの詳細な実装手順を記載。SKILL.md の概要と合わせて参照すること。

## フェーズ 1: request

**目的**: ユーザーの要望を整理し、Issue として記録する。

### 実行条件

該当 Issue が見つからないときは**必ず以下を実行すること**。説明だけして「Issue を作成しましょうか？」などと聞いて終えてはならない。

### 手順

1. **採番**: `issues/` をスキャンし、ディレクトリ名が `issue_NNN_*` の NNN 部分の最大+1、3桁ゼロパッド（無→`001`）
2. **スラッグ**: 要望（raw_input）またはタイトルから短いスラッグを生成。英小文字・数字・ハイフンのみ、スペースはハイフンに。目安20文字以内。取得困難な場合は `untitled` 等の既定スラッグを使う
3. **作成**: `issues/issue_NNN_slug/` を作成。`id` は `issue_NNN_slug`
4. **コピー**: `./assets/` から `request.yaml`, `phase.yaml` をコピー
5. **記録**: `request.yaml` の `id`, `title`, `raw_input`, `created_at` を設定
6. **phase.yaml**: `current_phase: 1`, フェーズ 1 `status: in_progress`, `waiting_approval: true`
7. **通知**: `bash scripts/ntfy.sh "📋 要望を整理しました（request）。レビューをお願いします"`
8. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

---

## フェーズ 2: business_requirements

**目的**: ビジネス観点での要件を整理し、ステークホルダー・目的・ゴールを明確化する。

### 手順

1. `phase.yaml`: `current_phase: 2`, `status: in_progress`
2. **ヒアリング**: `request.yaml`（要望）を踏まえ、ユーザーに**適度にヒアリング**する
3. `./assets/business-requirements.md` を `issues/<issue_id>/business-requirements.md` にコピー
4. `request.yaml` の raw_input / title および**ヒアリング結果**に沿って、概要・目的・ゴール・ステークホルダー・機能要件（ハイレベル）・非機能要件・制約・前提条件・受け入れ基準を記載
5. `phase.yaml`: `waiting_approval: true` に更新
6. **通知**: `bash scripts/ntfy.sh "📋 ビジネス要件を書きました。レビューをお願いします"`
7. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

### ヒアリングガイド

#### 基本方針

- **過不足なく**: 聞きすぎず、抜け漏れのない程度に質問する。
- **要望の再確認**: request の意図を明確な用語で確認する（要件の再確認→明確化の流れを心がける）。
- **回答を反映**: ヒアリング結果をそのままビジネス要件の各セクションに反映する。

#### 質問例（テーマごと）

以下は「必ず聞く」ではなく、request の内容に応じて選んで使う。

**目的・ゴール**
- 「この要望で、一番達成したいことは何ですか？」
- 「完了のイメージ（どうなっていれば成功ですか）を教えてください。」

**ステークホルダー**
- 「主に誰が使う／影響を受ける想定ですか？」
- 「意思決定や承認は誰が行いますか？」

**制約・前提条件**
- 「期限や予算、技術的な制約はありますか？」
- 「前提にしている環境やルール（例: rulesync 利用、.cursor は generate で生成）があれば教えてください。」

**受け入れ基準**
- 「どこまでできたら"完了"とみなしますか？」
- 「レビューで見てほしいポイントはありますか？」

**スコープの切り方**
- 「今回は phase 2 に絞る／全体を触る、などスコープの希望はありますか？」
- 「今回の Issue では扱わないことにしたいものはありますか？」

#### ヒアリングの流れ（推奨）

1. request.yaml の raw_input / title を要約し、理解した内容を短く伝える。
2. 上記テーマのうち、要望からは読み取りにくい点について 1〜3 問程度質問する（まとめて聞いてよい）。
3. ユーザーの回答を受けてから、business-requirements.md の作成に進む。
4. 成果物を出したあとは、承認待ちで会話を終了する（従来どおり）。

#### 注意

- ヒアリングは**同一ターン内**で完結させる。必要以上に何度も往復しない。
- ユーザーが「とくにない」「そのままでよい」と答えた項目は深掘りしない。

---

## フェーズ 3: system_requirements

**目的**: システム観点での要件を整理し、システム境界・機能制約・非機能要件を明確化する。

### 手順

1. `phase.yaml`: `current_phase: 3`, `status: in_progress`
2. **ヒアリング**: `request.yaml` と `business-requirements.md` を踏まえ、ユーザーに**適度にヒアリング**する
3. `./assets/system-requirements.md` を `issues/<issue_id>/system-requirements.md` にコピー
4. 要望・ビジネス要件および**ヒアリング結果**に沿って、各セクションを記載
5. `phase.yaml`: `waiting_approval: true` に更新
6. **通知**: `bash scripts/ntfy.sh "📋 システム要件を書きました。レビューをお願いします"`
7. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

### ヒアリングガイド

#### 基本方針

- **フェーズ 2 と同じ要領**: 聞きすぎず、抜け漏れのない程度に。1〜3 問程度にまとめる。
- **要望・ビジネス要件の再確認**: request と business-requirements を踏まえ、システム境界・スコープが不明な点を確認する。
- **回答を反映**: ヒアリング結果を system-requirements.md の該当セクションにそのまま反映する。

#### 質問例（テーマごと）

request の内容に応じて選んで使う。

**システム境界・スコープ**
- 「システムとして対象にしたい範囲はどこまでですか？」
- 「今回の Issue ではシステム要件に含めないことにしたいものはありますか？」

**機能・制約**
- 「主要な機能で、入出力や制約で決めておきたい点はありますか？」
- 「既存の仕様や制約で前提にしているものはありますか？」

**非機能**
- 「応答時間・可用性・セキュリティなど、重視したい点はありますか？」

**受け入れイメージ（システム要件レベル）**
- 「システム要件書でここまで書けていればよい、というイメージはありますか？」

#### ヒアリングの流れ（推奨）

1. request と business-requirements の要点を短く要約し、理解した内容を伝える。
2. 上記テーマのうち、システム要件として不足しそうな点について 1〜3 問程度質問する。
3. ユーザーの回答を受けてから、system-requirements.md の作成に進む。
4. 成果物を出したあとは、承認待ちで会話を終了する。

---

## フェーズ 4: detailed_design

**目的**: 実装レベルの詳細設計を記述する。

### 手順

1. `phase.yaml`: `current_phase: 4`, `status: in_progress`
2. `./assets/detailed-design.md` を `issues/<issue_id>/detailed-design.md` にコピーし、要望に沿って記載
3. `phase.yaml`: `waiting_approval: true` に更新
4. **通知**: `bash scripts/ntfy.sh "📋 詳細設計を書きました。レビューをお願いします"`
5. **⛔ 承認を待つ — ここで会話を終了。次の発言まで何もしない**

---

## フェーズ 5: development

**目的**: 実装を行う。

### 手順

1. `phase.yaml`: `current_phase: 5`, `status: in_progress`
2. **タスク記憶の参照**: `issues/<issue_id>/tasks/development.yaml` があれば読む（形式は [`schemas/tasks-schema.md`](schemas/tasks-schema.md) 参照）
3. **作業ブランチ**:
   - **`git_command: enabled`**: Issue 実行時のブランチで作業。必要なら作業ブランチ作成（例: `feature/issue_001_xxx`）
   - **`git_command: disabled`**: git コマンド不可。ユーザーが適切なブランチにいることを前提に作業
4. `request.yaml` の `project_ids` の全リポジトリで実装
5. **タスク記憶の更新**: タスク進行時に `issues/<issue_id>/tasks/development.yaml` の `status` / `summary` / `updated_at` を更新（ディレクトリ `tasks/` が無ければ作成）
6. **コミット**:
   - **`git_command: enabled`**: ローカルコミット実行
   - **`git_command: disabled`**: 変更ファイル一覧を伝え「現在のブランチでコミットしてください」
7. 完了後フェーズ 6 へ

### git_command の扱い

`config/projects.yaml` の各プロジェクトで `git_command` 設定を確認:

- **`enabled`** (デフォルト): AI がすべての git コマンドを実行可能
- **`disabled`**: AI は該当プロジェクトで**いかなる git コマンドも実行しない**。ファイル編集のみ実行し、git 操作はすべてユーザーに委ねる

詳細は [`config-reference.md`](config-reference.md) と [`../../rules/git-command.md`](../../rules/git-command.md) を参照。

---

## フェーズ 6: code_review

**目的**: コードレビューを実施する。

### 手順

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

### review_method の扱い

- **`pr`**: AI が push して PR を作成。マージ後にクローズ。`git_command: enabled` の場合のみ有効。
- **`local_diff`**: PR は作らない。ユーザーが手元で diff を確認して承認。`git_command: disabled` の場合は必須。

詳細は [`config-reference.md`](config-reference.md) を参照。

---

## フェーズ 7: close

**目的**: Issue をクローズする。

### 手順

1. フェーズ 6 が完了したタイミングで、`phase.yaml` の全フェーズを `completed` にして Issue をクローズする。
