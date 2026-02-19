---
targets: ["*"]
description: "projects.yaml で管理されるプロジェクトの git コマンド実行制限ルール"
globs: ["**/*"]
---

# Git コマンド実行制限ルール

このルールは `config/projects.yaml` で管理されているプロジェクトに対して、`git_command` 設定に基づいた git コマンドの実行制限を適用します。

## 基本方針

AI は `config/projects.yaml` を参照し、各プロジェクトの `git_command` 設定（`enabled` または `disabled`）を把握してから作業を開始します。

## git_command: disabled の場合

以下のプロジェクトに対しては、**いかなる git コマンドも実行しません**:

```yaml
# config/projects.yaml の例
projects:
  - id: example_project
    path: "~/Work/example"
    git_command: disabled  # この設定の場合
```

### 禁止事項

1. **すべての git コマンドの実行禁止**
   - `git log` - コミット履歴の表示
   - `git diff` - 差分の表示
   - `git show` - コミット内容の表示
   - `git blame` - 行ごとの変更履歴
   - `git status` - 作業ツリーの状態確認
   - `git branch` - ブランチ一覧
   - `git checkout` - ブランチ切り替え
   - `git add` - ステージング
   - `git commit` - コミット作成
   - `git push` - リモートへのプッシュ
   - `git pull` - リモートからのプル
   - その他すべての git サブコマンド

2. **`.git` ディレクトリへの直接アクセス禁止**
   - `cat .git/config` - git 設定ファイルの読み取り
   - `ls .git/` - .git ディレクトリの内容確認
   - `.git` 配下のあらゆるファイルへのアクセス

### ユーザーが明示的に指示した場合の応答

ユーザーが「コミット履歴を見せて」「git log を実行して」等の指示をしても、以下のように応答します:

```
このプロジェクト（[project_id]）は config/projects.yaml で git_command: disabled に設定されているため、
git コマンドの実行やコミット履歴の表示はできません。

必要であれば、ターミナルで直接実行してください:
  cd [project_path]
  git log
```

### 例外: ファイル編集は可能

`git_command: disabled` でも、以下のファイル操作は**通常通り実行可能**です:

- `Read` - ファイルの読み取り
- `Write` - ファイルの書き込み
- `StrReplace` - ファイルの編集
- `Grep` - ファイル内検索
- `Glob` - ファイルパターン検索
- その他のファイルシステム操作

## git_command: enabled の場合

`git_command: enabled` または設定が省略されている場合は、通常通りすべての git コマンドを実行できます。

## プロジェクトパスの判定

AI は以下の手順でプロジェクトを識別します:

1. 操作対象のファイルパスを取得
2. `config/projects.yaml` の各 `path` とマッチングを試行
3. マッチしたプロジェクトの `git_command` 設定を確認
4. `disabled` の場合は git コマンドを実行しない

## 設定ファイルの参照

このルールは以下のファイルを参照します:

- [`config/projects.yaml`](../config/projects.yaml) - プロジェクト一覧と git_command 設定
