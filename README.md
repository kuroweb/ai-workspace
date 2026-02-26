# ai-workspace

マルチプロジェクト開発用ワークスペース。

- **Cursor**: `ai-workspace.code-workspace` をマルチルートワークスペースとして開いて横断的に開発
- **Claude Code**: `projects/` 配下に複数のリポジトリをクローンして横断的に開発
- **Codex**: `ai-workspace` をルートに開き、`projects/` 配下の複数リポジトリを横断的に開発
- **仕様駆動開発**: `.kiro/` で要件 → 設計 → タスク → 実装の流れをサポート

## セットアップ

```bash
# 1. クローン
git clone <repository-url>
cd ai-workspace

# 2. 設定ファイル作成
cp config/settings.yaml.example config/settings.yaml

# 3. 開発対象のリポジトリを projects/ 以下に配置（必須）
git clone <repository-url> projects/your-repo

# 4. MCP サーバー設定（任意）
cp .env.example .env
# .env にトークン等を設定

# Claude Code 用 MCP 設定
cp .mcp.json.example .mcp.json

# Cursor 用 MCP 設定
cp .cursor/mcp.json.example .cursor/mcp.json

# 5. 通知テスト（任意）
bash scripts/ntfy.sh "テスト通知"
```

### 設定ファイル

| ファイル | 用途 |
|----------|------|
| **config/settings.yaml** | ntfy トピック設定、`git_command`（AI の git 実行可否: `true` / `false`、未設定時は `false`） |
| **.env** | MCP サーバーの認証情報（任意） |
| **.mcp.json** | Claude Code 用 MCP サーバー設定（`.mcp.json.example` をコピーして使用） |
| **.cursor/mcp.json** | Cursor 用 MCP サーバー設定（`.cursor/mcp.json.example` をコピーして使用） |

## 開発スタイル

### Claude Code

**ai-workspace をルートとして開く**。開発対象リポジトリは **`projects/`** 配下にクローンで配置する。

```bash
git clone <repository-url> projects/your-repo
```

### Cursor

**`ai-workspace.code-workspace`** をワークスペースファイルとして開く。プロジェクトを追加する場合は `folders` に追記する。

```bash
cursor ai-workspace.code-workspace
```

### Kiro を使った開発フロー

1. **プロジェクト方針の設定** - `/kiro:steering` でプロジェクト全体の方針を `.kiro/steering/` に記録
2. **機能仕様の作成** - `/kiro:spec-init "機能説明"` で新規仕様を作成
3. **要件・設計・タスク** - `/kiro:spec-requirements`, `/kiro:spec-design`, `/kiro:spec-tasks` で段階的に定義
4. **実装** - `/kiro:spec-impl` で TDD ベースの実装
5. **進捗確認** - `/kiro:spec-status` でステータス確認

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
├── .rulesync/                  # rules / skills / subagents の編集正本
│   ├── rules/                  # ルール定義（git 管理）
│   ├── skills/                 # スキル定義（git 管理）
│   └── subagents/              # サブエージェント定義（git 管理）
├── .cursor/                    # Cursor 用設定
│   ├── commands/kiro/          # Kiro コマンド（git 管理）
│   ├── rules/                  # ルール（rulesync で生成）
│   ├── mcp.json                # MCP 設定（git 管理外、*.example からコピー）
│   └── mcp.json.example        # MCP 設定サンプル（git 管理）
├── .claude/                    # Claude Code 用設定
│   ├── commands/kiro/          # Kiro コマンド（git 管理）
│   ├── rules/                  # ルール（rulesync で生成）
│   └── settings.local.json     # 設定（rulesync で生成）
├── .mcp.json                   # Claude Code 用 MCP 設定（git 管理外、*.example からコピー）
├── .mcp.json.example           # Claude Code 用 MCP 設定サンプル（git 管理）
├── .codex/                     # Codex CLI 用設定
│   ├── prompts/kiro-*.md       # Kiro プロンプト（git 管理）
│   └── memories/               # メモリ（rulesync で生成）
├── scripts/                    # ユーティリティスクリプト
│   ├── agent-import.sh         # 設定インポートスクリプト
│   └── ntfy.sh                 # 通知スクリプト
├── AGENTS.md                   # エージェント設定マニフェスト（rulesync で生成・git 管理外）
├── CLAUDE.md                   # Claude プロジェクト指示（rulesync で生成・git 管理外）
├── ai-workspace.code-workspace # Cursor 用マルチルートワークスペース設定（git 管理）
└── rulesync.jsonc              # rulesync 設定
```

## AI エージェント設定

### rulesync で共通管理

`.rulesync/` で編集し、`rulesync generate` で各エージェント向けに展開する。

| 編集正本 | Cursor | Claude Code | Codex |
| --- | --- | --- | --- |
| `.rulesync/rules/` | `.cursor/rules` | `.claude/rules` | `.codex/memories` |
| `.rulesync/rules/overview.md` | `.cursor/rules/overview.mdc` | `CLAUDE.md` | `AGENTS.md` |
| `.rulesync/skills/` | `.cursor/skills` | `.claude/skills` | `.codex/skills` |
| `.rulesync/subagents` | `.cursor/subagents` | `.claude/subagents` | `.codex/subagents` |

詳細は `rulesync.jsonc` を参照。

### 個別管理

各エージェントのディレクトリを直接編集する。

| 項目 | Cursor | Claude Code | Codex |
| --- | --- | --- | --- |
| MCP 設定 | `.cursor/mcp.json` | `.mcp.json` | - |
| Kiro コマンド | `.cursor/commands/kiro/` | `.claude/commands/kiro/` | `.codex/prompts/` |

## コマンドリファレンス

### rulesync generate

`.rulesync/` の編集正本から各エージェント用設定（`.cursor/`, `.claude/`, `.codex/`）を生成する。

```bash
rulesync generate
```

### agent-import

`--from` で指定したパスから `.rulesync/` 相当の設定をコピーして取り込む。テンプレートやチーム共有の設定を流用するとき、別環境へのセットアップ時に使用。

```bash
cd /path/to/ai-workspace

# 全てを一括で取り込む（既存はスキップ）
./scripts/agent-import.sh --all --from /path/to/source

# 上書きする場合
./scripts/agent-import.sh --all --force --from /path/to/source
```

一部だけ取り込む場合は `--skills` / `--rules` / `--subagents` で対象を指定する。

```bash
./scripts/agent-import.sh --skills plan --from /path/to/source  # スキル1つだけ
./scripts/agent-import.sh --skills-all --from /path/to/source   # スキル全件
./scripts/agent-import.sh --rules-all --from /path/to/source    # ルール全件
```

#### オプション

| オプション | 意味 |
| --- | --- |
| `--all` | skills, rules, subagents を全て取り込む |
| `--force` | 既存ファイルを上書きする（省略時はスキップ） |
| `--from <path>` | コピー元（ワークスペースルートか `.rulesync` のパス） |

**一部だけ取り込む場合**（`--all` の代わりに以下を指定）:

| オプション | 意味 |
| --- | --- |
| `--skills <name>` / `--skills-all` | スキルを1つ / 全件 |
| `--rules <name>` / `--rules-all` | ルールを1つ / 全件 |
| `--subagents <name>` / `--subagents-all` | サブエージェントを1つ / 全件 |

### ntfy 通知テスト

```bash
bash scripts/ntfy.sh "テスト通知"
```
