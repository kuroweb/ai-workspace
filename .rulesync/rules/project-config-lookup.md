---
targets: ["*"]
description: "プロジェクト名/ID/パスが言及された場合、config/projects.yaml を参照してプロジェクト設定を確認する"
globs: ["**/*"]
---

# プロジェクト設定参照

プロジェクト情報は `config/projects.yaml` に集約される。プロジェクト名・ID・パスが言及された場合、まず `config/projects.yaml` を参照してプロジェクト設定を確認する。パスを自力で探索してはいけない。

## 基本原則

**プロジェクト情報の単一情報源（SSOT）は `config/projects.yaml` である。**

プロジェクト名が言及された場合（dev-workflow スキル、通常の作業、その他すべてのコンテキスト問わず）、自動的に `config/projects.yaml` を参照し、以下の情報を確認してから作業を進める。

## 処理フロー

### 1. トリガー認識

以下の場合に発動：
- プロジェクト ID が言及された（例："ai-workspace で...")
- プロジェクト名（name フィールド）が言及された（例："Price Monitoring で...")
- プロジェクトパスが言及された（例:"~/environment/price-monitoring で...")

### 2. プロジェクト設定の確認

`config/projects.yaml` を参照し、該当プロジェクトをマッチングする。

マッチング優先順序：
1. `id` フィールドの完全一致
2. `name` フィールド（大文字小文字区別なし）
3. `path` フィールド（相対パス・絶対パスの両方に対応）

### 3. 確認する項目

マッチしたプロジェクトから以下を抽出：

| フィールド | 用途 |
|-----------|------|
| `path` | 作業対象ディレクトリ |
| `git_command` | git コマンド実行可否（git-command.md へ） |
| `repo` | リポジトリ URL |
| `default_branch` | デフォルトブランチ |
| `notes` | プロジェクト説明 |

### 4. 確認後の動作

抽出した設定に基づいて以降の作業を進める：

- `git_command: disabled` の場合、git-command.md ルールを適用（git コマンド禁止）
- `path` を作業対象として使用
- `repo` 情報をもとに GitHub リンク等を構築

## 禁止事項

❌ パスが言及されても projects.yaml を見ずに Glob/Grep でパス探索
❌ プロジェクト名が言及されても projects.yaml を見ずに手動確認
❌ projects.yaml と異なる情報をもとに作業を進める

## 実装例

**ユーザー指示：**
```
[プロジェクト ID] で Foo.ts を編集して
```

**AI の処理：**
```
1. config/projects.yaml を参照
2. [プロジェクト ID] にマッチ（id フィールド）
3. 設定を確認：
   - path: <プロジェクトパス>
   - git_command: <enabled|disabled>
   - repo: <リモートリポジトリ URL>
4. <プロジェクトパス>/Foo.ts を対象に編集を実行
```

**ユーザー指示：**
```
[プロジェクト ID] でコードを実装して
```

**AI の処理：**
```
1. config/projects.yaml を参照
2. [プロジェクト ID] にマッチ
3. 設定を確認：
   - git_command: <enabled|disabled> ← この設定に基づく
4. git_command: disabled の場合、git-command.md ルールを適用
   （git コマンド実行不可。ファイル編集のみ）
```

## マッチなしの場合

`config/projects.yaml` にマッチするプロジェクトがない場合は以下のように対応：

```
指定されたプロジェクト「[name]」が config/projects.yaml に見つかりません。

config/projects.yaml にプロジェクトを追加してください。以下のテンプレートを参考に：

  - id: [プロジェクト ID]
    name: "[プロジェクト名]"
    path: "[ローカルパス]"
    repo: "[リモートリポジトリ URL]"
    default_branch: [デフォルトブランチ]
    git_command: [enabled|disabled]
    notes: |
      - [説明]
```

### 参考値

- `id`: リポジトリ識別子（英小文字・ハイフン区切り。`project_ids` で参照される）
- `name`: 表示用プロジェクト名
- `path`: `~/environment/[name]` など相対パスを推奨
- `repo`: `github.com/user/repo` 形式
- `default_branch`: `main` または `master`
- `git_command`: AI が git コマンド実行可能かどうか（デフォルト: `disabled`）
- `notes`: プロジェクトの説明（複数行可）

## 参照するファイル

- [`config/projects.yaml`](../config/projects.yaml) - プロジェクト一覧
- [`git-command.md`](git-command.md) - git コマンド実行制限
