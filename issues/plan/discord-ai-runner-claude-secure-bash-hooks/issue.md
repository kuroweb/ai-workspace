# discord-ai-runner: Claude Hookで --dangerously-skip-permissions を安全運用する

- 作成日: 2026-03-05
- Category: タスク
- 実行対象: `discord-ai-runner`

## 概要

`discord-ai-runner` で Claude 実行時に `--dangerously-skip-permissions` を使う前提とし、`.claude` の Hook（`PreToolUse`）で Bash 実行を実行前に検査・ブロックする安全運用を整備する。

## 背景

- `dangerously-skip-permissions` は利便性が高い一方、誤実行時の破壊範囲が大きい。
- 単一ガードではなく、runner側の運用ルールと Claude Hook 側制御（deny）を重ねる必要がある。

## 要件

1. `.claude/settings.json` に `hooks.PreToolUse`（`Bash`）と `permissions.deny` を定義すること。
2. `.claude/settings.local.json` は開発者ごとの任意上書き用途に限定し、必須の deny ルールを無効化しない運用とすること。
3. `.claude/settings.local.json.example` を `cp` して `.claude/settings.local.json` を作成する運用を README に明記すること。
4. `.claude/settings.local.json` は `.gitignore` に追加し、Git 管理対象外にすること。
5. `.claude/hooks/deny-check.sh` で Bash コマンドを検査し、拒否時は Hook仕様の拒否レスポンスを返すこと。
6. runner 側 dangerous 運用と Hook運用が整合すること。

## 実装方針（案）

- 設定配置:
  - `discord-ai-runner/.claude/settings.json`（必須・共有）
  - `discord-ai-runner/.claude/settings.local.json.example`（任意・ローカル上書き用サンプル）
  - `discord-ai-runner/.claude/hooks/deny-check.sh`
- denyルールは初期は厳格に設定し、誤検知を見ながら allow を最小追加する。
- runner 側は現行の dangerous policy を維持し、二重防御にする。
- `.claude/settings.local.json` を使う場合も、`.claude/settings.json` の必須 deny ルールを打ち消さないことをレビュー項目に含める。
- ローカル設定は `cp .claude/settings.local.json.example .claude/settings.local.json` で作成し、`.claude/settings.local.json` は `.gitignore` で除外する。

### 想定ファイル構成

```text
discord-ai-runner/
├── .claude/
│   ├── settings.json
│   ├── settings.local.json.example
│   └── hooks/
│       └── deny-check.sh
├── .gitignore
└── README.md
```

### テンプレート案

`discord-ai-runner/.claude/settings.json`（必須・共有）

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/deny-check.sh\""
          }
        ]
      }
    ]
  },
  "permissions": {
    "deny": [
      "Bash(sudo:*)",
      "Bash(rm -rf /:*)",
      "Bash(curl *|* sh:*)",
      "Bash(wget *|* sh:*)"
    ]
  }
}
```

`discord-ai-runner/.claude/settings.local.json.example`（任意・ローカル上書き用サンプル）

```json
{
  "permissions": {}
}
```

`discord-ai-runner/.claude/hooks/deny-check.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly LOG_FILE="${CLAUDE_HOOK_LOG_FILE:-/tmp/claude-deny-check.log}"
readonly TS="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

log() {
  # 監査用ログ（失敗しても本処理は継続）
  printf '%s %s\n' "$TS" "$1" >>"$LOG_FILE" 2>/dev/null || true
}

deny() {
  local reason="$1"
  log "DENY reason=${reason}"
  printf '{"decision":"deny","reason":"%s"}\n' "$reason"
  exit 0
}

allow() {
  log "ALLOW"
  printf '{"decision":"allow"}\n'
  exit 0
}

input="$(cat || true)"
if [[ -z "${input}" ]]; then
  deny "Empty hook input (fail-closed)"
fi

if ! command -v jq >/dev/null 2>&1; then
  deny "jq is required for deny-check.sh (fail-closed)"
fi

# Claude Hook入力JSONの command を取得（キー差異は必要に応じて調整）
command="$(
  echo "$input" | jq -r '
    .tool_input.command
    // .toolInput.command
    // .command
    // empty
  '
)"

if [[ -z "${command}" ]]; then
  deny "Command not found in hook payload (fail-closed)"
fi

deny_regex='(rm[[:space:]]+-rf[[:space:]]+/|(^|[[:space:]])sudo([[:space:]]|$)|curl[[:space:]].*\|[[:space:]]*sh|wget[[:space:]].*\|[[:space:]]*sh)'
if echo "$command" | grep -Eiq "$deny_regex"; then
  deny "Dangerous command detected"
fi

allow
```

## 受け入れ条件

- 正常系:
  - 安全な Bash コマンドは実行継続される。
  - `--dangerously-skip-permissions` 前提でも、ガードレールにより安全に運用できる。
- 異常系:
  - `sudo` / `rm -rf /` / `curl | sh` など拒否対象は実行前に停止される。
  - Hookエラー時に fail-closed（停止）で運用できる。
- 運用:
  - 設定変更の反映手順（launchd再起動含む）が README で追える。

## タスク分解

- [ ] `.claude/settings.json` の初期テンプレート整備（必須ルール）
- [ ] `.claude/settings.local.json.example` の運用ガイド整備（任意上書きの境界明記）
- [ ] `.gitignore` に `.claude/settings.local.json` を追加
- [ ] `.claude/hooks/deny-check.sh` 実装（実行権限付与含む）
- [ ] dangerous policy と Hook運用の整合確認
- [ ] 拒否/許可の動作確認ケース作成
- [ ] README に導入手順・`cp` 手順・ロールバック手順を追記

## リスクと対策

- リスク: deny を厳しくしすぎて運用停止する。
  - 対策: 段階導入（dry-run相当ログ確認 -> 本番拒否）、限定スレッドで先行適用。
- リスク: 設定分散で管理が破綻する。
  - 対策: runner リポジトリ配下に設定を集約し、README に正本を明記。

## メモ

- 参照: https://wasabeef.jp/blog/claude-code-secure-bash
- 公式仕様との差分が出た場合は Anthropic Hooks 公式ドキュメントを優先する。
