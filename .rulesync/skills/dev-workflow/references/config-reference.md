# config/projects.yaml 設定リファレンス

開発対象プロジェクトの設定項目と、git_command / review_method の関係を定義する。

## 開発対象リポジトリとの連携

- `request.yaml` の `project_ids` に列挙した id と一致する `config/projects.yaml` の要素の `path` が、この Issue で扱うリポジトリ全体。
- フェーズ 5（development）: 列挙した**すべての**リポジトリで実装。`git_command` により git コマンドの実行可否が決まる。
  - `git_command: enabled`（デフォルト）: AI がローカルコミットを実行
  - `git_command: disabled`: AI はファイル編集のみ行い、git 操作はユーザーが手元で実施
- フェーズ 6（code_review）: レビュー方法はプロジェクトの `review_method`（必須）に従う（下記）。
  - `review_method: pr`: AI が PR を作成（`git_command: enabled` の場合のみ有効）
  - `review_method: local_diff`: ユーザーが手元で diff を確認して承認
- デプロイ設定は開発対象リポジトリ側に配置

---

## git_command と review_method の関係

| `git_command` | `review_method` | 有効性 | 説明 |
| --- | --- | --- | --- |
| `enabled` | `pr` | ○ | AI が git コマンド実行・PR 作成を行う（標準） |
| `enabled` | `local_diff` | ○ | AI が git コマンド実行するが PR は作らない |
| `disabled` | `pr` | ✗ | **無効**（PR 作成には git push が必要）。起動時のバリデーションでエラー |
| `disabled` | `local_diff` | ○ | AI はファイル編集のみ。git 操作とレビューはすべてユーザーが実施 |

---

## config/projects.yaml の項目

| キー | 必須 | 説明 |
| --- | --- | --- |
| `id` | ○ | request.yaml の `project_ids` で参照する識別子。 |
| `name` | ○ | プロジェクト名（表示・メモ用）。 |
| `path` | ○ | リポジトリのローカルパス。この Issue で扱う実体。 |
| `repo` | ○ | リモートリポジトリ（例: `github.com/user/repo`）。 |
| `default_branch` | ○ | デフォルトブランチ（例: `main`, `master`）。 |
| `git_command` | - | AI の git コマンド実行を制御。`enabled` または `disabled`。デフォルト: `disabled`。詳細は [`../rules/git-command.md`](../../rules/git-command.md) を参照。 |
| → `enabled` | | AI がすべての git コマンドを実行可能。 |
| → `disabled` | | AI は該当プロジェクトで**いかなる git コマンドも実行しない**。ファイル編集のみ行い、git 操作はすべてユーザーに委ねる。`disabled` の場合は `review_method: local_diff` 必須。 |
| `review_method` | ○ | フェーズ 6 のレビュー方法。`pr` または `local_diff`。 |
| → `pr` | | AI が push して PR を作成。マージ後にクローズ。`git_command: enabled` の場合のみ有効。 |
| → `local_diff` | | PR は作らない。ユーザーが手元で diff を確認して承認。`git_command: disabled` の場合は必須。 |
| `notes` | - | 自由記述のメモ。 |

---

## git_command ルール詳細

AI は `config/projects.yaml` を参照し、各プロジェクトの `git_command` 設定（`enabled` または `disabled`）を把握してから作業を開始します。

**`git_command: disabled` の場合、AI は該当プロジェクトで以下のすべてを禁止:**

- すべての git コマンドの実行（`git log`, `git diff`, `git status`, `git add`, `git commit`, `git push`, `git pull` 等）
- `.git` ディレクトリへの直接アクセス

**例外: ファイル編集は可能**

`git_command: disabled` でも、以下のファイル操作は通常通り実行可能:

- Read, Write, StrReplace, Grep, Glob 等のファイルシステム操作

詳細は [`../../rules/git-command.md`](../../rules/git-command.md) を参照。
