# ai-workspace

AI エージェント設定（rules, skills, subagents, commands, MCP）を一元管理し、複数のエージェント（Cursor, Claude Code, Codex CLI）に展開する基盤リポジトリ。

## 概要

このリポジトリは以下を提供する：

- **AI エージェント設定の一元管理** - `.rulesync/` を編集正本として、複数のエージェント用設定を自動生成
- **rules / skills / subagents** - ルール、スキル、サブエージェントの定義（リポジトリごとに差異あり）

## リポジトリ構成

```
ai-workspace/
├── config/                     # 設定ファイル
│   └── settings.yaml           # 通知設定（git 管理外）
├── issues/                     # Issue 単位の成果物（git 管理外）
│   └── {issue-id}/
├── projects/                   # 各リポジトリへのシンボリックリンクを配置
├── .rulesync/                  # AI エージェント設定の編集正本
│   ├── rules/                  # ルール定義
│   ├── skills/                 # スキル定義
│   ├── subagents/              # サブエージェント定義
│   ├── commands/               # カスタムコマンド
│   └── mcp.json                # MCP サーバー設定（git 管理外）
├── .cursor/                    # Cursor 用（rulesync で自動生成・git 管理外）
├── .claude/                    # Claude Code 用（rulesync で自動生成・git 管理外）
├── .codex/                     # Codex CLI 用（rulesync で自動生成・git 管理外）
├── scripts/                    # ユーティリティスクリプト
├── AGENTS.md                   # エージェント設定（rulesync で自動生成・git 管理外）
├── CLAUDE.md                   # Claude 設定（rulesync で自動生成・git 管理外）
└── rulesync.jsonc              # rulesync 設定
```

**重要**: `.rulesync/` が編集正本。変更後は `rulesync generate` で各エージェント用設定を展開すること。

rules / skills / subagents の詳細は `.rulesync/` 内の各リポジトリを参照。

## セットアップ

```bash
# 1. クローン
git clone <repository-url>
cd ai-workspace

# 2. 設定ファイル作成
cp config/settings.yaml.example config/settings.yaml
cp .env.example .env  # MCP使用時のみ
cp .rulesync/mcp.json.example .rulesync/mcp.json  # MCP使用時のみ

# 3. エージェント設定の生成
brew install rulesync
rulesync generate

# 4. 開発対象のリポジトリを projects/ 以下にシンボリックリンクで配置する（必須）
ln -s /path/to/your-repo projects/your-repo

# 5. 通知テスト
bash scripts/ntfy.sh "テスト通知"
```

## スキル・ルールのインポート

`--from` で指定したパスから、`.rulesync/` 相当の設定をコピーして取り込む。

**利用シーン**: テンプレートやチーム共有の設定を流用するとき、別環境へのセットアップ時。

### 実行例

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

### オプション

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

## 設定ファイル

- **config/settings.yaml** - ntfy トピック設定、`git_command`（AI の git 実行可否: `enabled` / `disabled`、未設定時は disabled）
- **.env** - MCP サーバーのトークン（任意）
- **.rulesync/mcp.json** - MCP サーバー設定（任意）
