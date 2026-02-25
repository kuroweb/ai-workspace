---
paths:
  - '**/*'
---
# Git コマンド実行制限ルール

このルールは **現在のワークスペース** に対して、`config/settings.yaml` の `git_command` 設定に基づいて git コマンドの実行可否を適用します。

## 基本方針

AI は作業前に `config/settings.yaml` を参照し、`git_command` の値（`enabled` または `disabled`）を確認する。**未設定のときは disabled** とする。

## git_command: disabled の場合

**いかなる git コマンドも実行しません。**

```yaml
# config/settings.yaml の例
git_command: disabled
```

### 禁止事項

1. **すべての git コマンドの実行禁止**
   - `git log` / `git diff` / `git show` / `git blame` / `git status` / `git branch` / `git checkout` / `git add` / `git commit` / `git push` / `git pull` など
2. **`.git` ディレクトリへの直接アクセス禁止**（`cat .git/config` 等）

### ユーザーが明示的に指示した場合の応答

「コミット履歴を見せて」「git log を実行して」等の指示に対し、以下のように応答します。

```
このワークスペースは config/settings.yaml で git_command: disabled に設定されているため、
git コマンドの実行やコミット履歴の表示はできません。

必要であれば、ターミナルで直接実行してください。
```

### 例外: ファイル編集は可能

`git_command: disabled` でも、Read / Write / StrReplace / Grep / Glob 等のファイル操作は通常通り実行可能です。

## git_command: enabled の場合

`git_command: enabled` と明示した場合のみ、git コマンドを実行できます。**未設定のときは disabled 扱い**です。

## 参照

- `config/settings.yaml` - `git_command` の設定
