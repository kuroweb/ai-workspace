# ai-workspace

AI エージェント設定（rules, skills, subagents, commands, MCP）を一元管理し、複数のエージェント（Cursor, Claude Code, Codex CLI）に展開する基盤リポジトリ。

## 概要

このリポジトリは以下を提供する：

- **AI エージェント設定の一元管理** - `.rulesync/` を編集正本として、複数のエージェント（Cursor, Claude Code, Codex CLI）用設定を自動生成
- **Kiro (Spec-Driven Development)** - `.kiro/` で仕様駆動開発をサポート（要件 → 設計 → タスク → 実装）
- **マルチリポジトリ開発** - `projects/` 配下に複数リポジトリを配置し、共通の AI 設定で開発

## リポジトリ構成

```
ai-workspace/
├── config/                     # 設定ファイル
│   ├── settings.yaml           # ワークスペース設定（git 管理外）
│   └── settings.yaml.example   # 設定サンプル
├── projects/                   # 開発対象リポジトリを配置（git 管理外）
├── .kiro/                      # Kiro (Spec-Driven Development)（git 管理外）
│   ├── settings/               # Kiro 設定テンプレート（git 管理）
│   ├── steering/               # プロジェクト全体の方針・ルール（インスタンス固有）
│   └── specs/                  # 機能仕様・タスク（インスタンス固有）
├── .rulesync/                  # AI エージェント設定の編集正本
│   ├── rules/                  # ルール定義（git 管理）
│   └── mcp.json                # MCP サーバー設定（git 管理外）
├── .cursor/                    # Cursor 用（rulesync で自動生成）
│   ├── commands/kiro/          # Kiro コマンド（git 管理・rulesync 管理外）
│   ├── rules/                  # ルール（rulesync で生成・git 管理外）
│   └── mcp.json                # MCP 設定（rulesync で生成・git 管理外）
├── .claude/                    # Claude Code 用（rulesync で自動生成）
│   ├── commands/kiro/          # Kiro コマンド（git 管理・rulesync 管理外）
│   ├── rules/                  # ルール（rulesync で生成・git 管理外）
│   └── settings.local.json     # 設定（rulesync で生成・git 管理外）
├── .codex/                     # Codex CLI 用（rulesync で自動生成）
│   ├── prompts/kiro-*.md       # Kiro プロンプト（git 管理・rulesync 管理外）
│   └── memories/               # メモリ（rulesync で生成・git 管理外）
├── scripts/                    # ユーティリティスクリプト
│   ├── agent-import.sh         # 設定インポートスクリプト
│   └── ntfy.sh                 # 通知スクリプト
├── AGENTS.md                   # エージェント設定マニフェスト（rulesync で生成・git 管理外）
├── CLAUDE.md                   # Claude プロジェクト指示（rulesync で生成・git 管理外）
└── rulesync.jsonc              # rulesync 設定
```

### 編集正本のルール

- **`.rulesync/rules/`** が AI エージェントルールの編集正本。変更後は `rulesync generate` で各エージェント用設定（`.cursor/`, `.claude/`, `.codex/`）を展開すること。
- **Kiro コマンド** (`.cursor/commands/kiro/`, `.claude/commands/kiro/`, `.codex/prompts/kiro-*.md`) は git 管理しているが、rulesync では管理していない（直接編集可能）。
- **`.kiro/steering/` と `.kiro/specs/`** はインスタンス固有（ワークスペースと projects の組み合わせごとに異なる）のため git 管理外。

## 開発スタイル

**ai-workspace をルートとして開く**。開発対象リポジトリは **`projects/`** 配下にクローン（またはシンボリックリンク）で配置する。

```bash
# クローンする場合
git clone <repository-url> projects/your-repo

# シンボリックリンクする場合
ln -s /path/to/your-repo projects/your-repo
```

Cursor / VSCode で **ai-workspace のルートフォルダ** を開けば、`projects/` 以下のリポジトリも一括で扱える。

### Kiro を使った開発フロー

1. **プロジェクト方針の設定** - `/kiro:steering` でプロジェクト全体の方針を `.kiro/steering/` に記録
2. **機能仕様の作成** - `/kiro:spec-init "機能説明"` で新規仕様を作成
3. **要件・設計・タスク** - `/kiro:spec-requirements`, `/kiro:spec-design`, `/kiro:spec-tasks` で段階的に定義
4. **実装** - `/kiro:spec-impl` で TDD ベースの実装
5. **進捗確認** - `/kiro:spec-status` でステータス確認

詳細は `CLAUDE.md` または各 Kiro コマンドのヘルプを参照。

## セットアップ

```bash
# 1. クローン
git clone <repository-url>
cd ai-workspace

# 2. 設定ファイル作成
cp config/settings.yaml.example config/settings.yaml
# ntfy トピックと git_command を編集（任意）

# 3. エージェント設定の生成
brew install rulesync
rulesync generate

# 4. 開発対象のリポジトリを projects/ 以下に配置（必須）
git clone <repository-url> projects/your-repo
# またはシンボリックリンク: ln -s /path/to/your-repo projects/your-repo

# 5. MCP サーバー設定（任意）
cp .env.example .env
# .env にトークン等を設定
# .rulesync/mcp.json を作成・編集後、rulesync generate で各エージェントに展開

# 6. 通知テスト（任意）
bash scripts/ntfy.sh "テスト通知"
```

### 設定ファイル

| ファイル | 用途 |
|----------|------|
| **config/settings.yaml** | ntfy トピック設定、`git_command`（AI の git 実行可否: `true` / `false`、未設定時は `false`） |
| **.env** | MCP サーバーの認証情報（任意） |
| **.rulesync/mcp.json** | MCP サーバー設定（任意、rulesync generate で各エージェントに展開） |

## コマンドリファレンス

### rulesync generate

`.rulesync/` の編集正本から各エージェント用設定（`.cursor/`, `.claude/`, `.codex/`）を生成する。

```bash
rulesync generate
```

### agent-import

`--from` で指定したパスから、`.rulesync/` 相当の設定をコピーして取り込む。テンプレートやチーム共有の設定を流用するとき、別環境へのセットアップ時に使用。

```bash
cd /path/to/ai-workspace

# 全てを一括で取り込む（既存はスキップ）
./scripts/agent-import.sh --all --from /path/to/source

# 上書きする場合
./scripts/agent-import.sh --all --force --from /path/to/source
```

一部だけ取り込みたい場合は、`--skills` / `--rules` / `--subagents` で対象を指定する。

```bash
./scripts/agent-import.sh --skills plan --from /path/to/source   # スキル1つだけ
./scripts/agent-import.sh --skills-all --from /path/to/source            # スキル全件
./scripts/agent-import.sh --rules-all --from /path/to/source             # ルール全件
./scripts/agent-import.sh --mcp --from /path/to/source                 # mcp.json.example のみ
```

#### オプション

| オプション | 意味 |
| --- | --- |
| `--all` | skills, rules, subagents, mcp を全て取り込む |
| `--force` | 既存ファイルを上書きする（省略時はスキップ） |
| `--from <path>` | コピー元（ワークスペースルートか `.rulesync` のパス） |

**一部だけ取り込む場合**（`--all` の代わりに以下を指定）:

| オプション | 意味 |
| --- | --- |
| `--skills <name>` / `--skills-all` | スキルを1つ / 全件 |
| `--rules <name>` / `--rules-all` | ルールを1つ / 全件 |
| `--subagents <name>` / `--subagents-all` | サブエージェントを1つ / 全件 |
| `--mcp` | `mcp.json.example` のみ（認証情報は含まない） |

### ntfy 通知テスト

```bash
bash scripts/ntfy.sh "テスト通知"
```

## トラブルシューティング

### Cursor でコード差分が正しく表示されない

`projects/` 配下にシンボリックリンクを置いた場合、Cursor で AI の変更を承認する際にエディタ上のインライン DIFF が正しく表示されないことがある。

**対処法**: `projects/` 配下のシンボリックリンクを `.code-workspace` ファイルに登録し、そのワークスペースファイルを Cursor で開く（マルチルートワークスペースとして開かれる）。設定例は `ai-workspace.code-workspace.example` を参照。
