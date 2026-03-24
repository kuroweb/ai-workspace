# ai-workspace

マルチプロジェクト開発用ワークスペース。

- **Cursor**: `ai-workspace.code-workspace` をマルチルートワークスペースとして開いて横断的に開発
- **Claude Code, Gemini CLI, Codex**: `ai-workspace` をルートに開き、`projects/` 配下の複数リポジトリを横断的に開発
- **仕様駆動開発**: `.kiro/` で要件 → 設計 → タスク → 実装の流れをサポート

## セットアップ

```bash
# 1. リポジトリのクローン
git clone <repository-url>
cd ai-workspace

# 2. 設定ファイル作成
cp config/settings.yaml.example config/settings.yaml

# 3. 開発対象リポジトリを projects/ に配置（必須）

## git cloneする場合:
git clone <repository-url> projects/your-repo

## symlinkを張る場合:
ln -s /path/to/repo projects/your-repo

# 4. 認証設定（任意）
cp .env.example .env

# 5. MCP 設定（任意）
cp .mcp.json.example .mcp.json
cp .cursor/mcp.json.example .cursor/mcp.json
cp .gemini/settings.json.example .gemini/settings.json
```

### 設定ファイル

| ファイル | 用途 |
|----------|------|
| **config/settings.yaml** | `git_command`（AI の git 実行可否: `true` / `false`、未設定時は `false`） |
| **.env** | 各種認証情報（API キー、トークン等） |
| **.mcp.json** | Claude Code 用 MCP サーバー設定（`.mcp.json.example` をコピーして使用） |
| **.cursor/mcp.json** | Cursor 用 MCP サーバー設定（`.cursor/mcp.json.example` をコピーして使用） |
| **.gemini/settings.json** | Gemini CLI 用 MCP サーバー設定（`.gemini/settings.json.example` をコピーして使用） |

## 開発スタイル

### Claude Code / Gemini CLI / Codex

**ai-workspace をルートとして開く**。開発対象リポジトリは **`projects/`** 配下にクローンまたはシンボリックリンクで配置し、これらを横断的に参照・編集する。

```bash
# Claude Code
claude

# Gemini CLI
gemini

# Codex
codex
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
├── projects/                   # 開発対象リポジトリ（クローン or symlink、git 管理外）
├── .kiro/                      # Kiro (Spec-Driven Development)（git 管理外）
│   ├── settings/               # Kiro 設定テンプレート
│   ├── steering/               # プロジェクト方針・ルール（インスタンス固有）
│   └── specs/                  # 機能仕様・タスク（インスタンス固有）
├── .rulesync/                  # rules / skills / subagents の編集正本
│   ├── rules/                  # ルール定義
│   ├── skills/                 # スキル定義
│   └── subagents/              # サブエージェント定義
├── .cursor/                    # Cursor 用設定
│   ├── commands/kiro/          # Kiro コマンド
│   ├── rules/                  # ルール（rulesync で生成）
│   ├── mcp.json                # MCP 設定（git 管理外、*.example からコピー）
│   └── mcp.json.example        # MCP 設定サンプル
├── .claude/                    # Claude Code 用設定
│   ├── commands/kiro/          # Kiro コマンド
│   ├── rules/                  # ルール（rulesync で生成）
│   └── settings.local.json     # 設定（rulesync で生成）
├── .mcp.json                   # Claude Code 用 MCP 設定（git 管理外、*.example からコピー）
├── .mcp.json.example           # Claude Code 用 MCP 設定サンプル
├── .codex/                     # Codex CLI 用設定
│   ├── prompts/kiro-*.md       # Kiro プロンプト
│   └── memories/               # メモリ（rulesync で生成）
├── .gemini/                    # Gemini CLI 用設定
│   ├── settings.json           # MCP 設定（git 管理外、*.example からコピー）
│   ├── settings.json.example   # MCP 設定サンプル
│   ├── memories/               # メモリ（rulesync で生成）
│   └── skills/                 # スキル（rulesync で生成）
├── scripts/                    # ユーティリティスクリプト
│   └── agent-import.sh         # 設定インポートスクリプト
├── AGENTS.md                   # エージェント設定マニフェスト（rulesync で生成・git 管理外）
├── CLAUDE.md                   # Claude プロジェクト指示（rulesync で生成・git 管理外）
├── GEMINI.md                   # Gemini CLI プロジェクト指示（rulesync で生成・git 管理外）
├── ai-workspace.code-workspace # Cursor 用マルチルートワークスペース設定
└── rulesync.jsonc              # rulesync 設定
```

## AI エージェント設定

### rulesync で共通管理

`.rulesync/` で編集し、`rulesync generate` で各エージェント向けに展開する。

| 編集正本 | Cursor | Claude Code | Codex | Gemini CLI |
| --- | --- | --- | --- | --- |
| `.rulesync/rules/` | `.cursor/rules` | `.claude/rules` | `.codex/memories` | `.gemini/memories` |
| `.rulesync/rules/overview.md` | `.cursor/rules/overview.mdc` | `CLAUDE.md` | `AGENTS.md` | `GEMINI.md` |
| `.rulesync/skills/` | `.cursor/skills` | `.claude/skills` | `.codex/skills` | `.gemini/skills` |
| `.rulesync/subagents` | `.cursor/subagents` | `.claude/subagents` | `.codex/subagents` | `.gemini/subagents` |

詳細は `rulesync.jsonc` を参照。

### 個別管理

各エージェントのディレクトリを直接編集する。

| 項目 | Cursor | Claude Code | Codex | Gemini CLI |
| --- | --- | --- | --- | --- |
| MCP 設定 | `.cursor/mcp.json` | `.mcp.json` | - | `.gemini/settings.json` |
| Kiro コマンド | `.cursor/commands/kiro/` | `.claude/commands/kiro/` | `.codex/prompts/` | - |

## コマンドリファレンス

### rulesync generate

`.rulesync/` の編集正本から各エージェント用設定（`.cursor/`, `.claude/`, `.codex/`, `.gemini/`）を生成する。

```bash
rulesync generate
```

