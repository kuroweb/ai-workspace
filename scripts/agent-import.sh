#!/usr/bin/env bash
# 既存はスキップしてインポート。--force で上書き。

# Examples:
#   ./scripts/agent-import.sh --all --from /path/to/source
#   ./scripts/agent-import.sh --all --force --from /path/to/source
#   ./scripts/agent-import.sh --skills plan --from /path/to/source

set -e

TYPE=""
NAME=""
FROM_RULESYNC=""
TARGET=""
FORCE=""

usage() {
  echo "❌ $1" >&2
  exit 1
}

get_workspace_root() {
  local d
  d="$(pwd)"
  while [[ -n "$d" && "$d" != "/" ]]; do
    if [[ -d "${d}/.rulesync" ]] || [[ -f "${d}/rulesync.jsonc" ]]; then
      echo "$d"
      return
    fi
    d="$(dirname "$d")"
  done
  echo ""
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills)
      TYPE="skills"
      NAME="${2:?--skills requires name}"
      shift 2
      ;;
    --skills-all)
      TYPE="skills-all"
      shift 1
      ;;
    --rules)
      TYPE="rules"
      NAME="${2:?--rules requires name}"
      shift 2
      ;;
    --rules-all)
      TYPE="rules-all"
      shift 1
      ;;
    --subagents)
      TYPE="subagents"
      NAME="${2:?--subagents requires name}"
      shift 2
      ;;
    --subagents-all)
      TYPE="subagents-all"
      shift 1
      ;;
    --mcp)
      TYPE="mcp"
      shift 1
      ;;
    --all)
      TYPE="all"
      shift 1
      ;;
    --from)
      FROM_RULESYNC="${2:?--from requires path}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift 1
      ;;
    -*)
      usage "未知のオプション: $1"
      ;;
    *)
      usage "予期しない引数: $1"
      ;;
  esac
done

TYPE_OPTS="--skills / --skills-all / --rules / --rules-all / --subagents / --subagents-all / --mcp / --all"
[[ -z "$TYPE" ]] && usage "${TYPE_OPTS} のいずれかを指定してください"

NO_NAME="mcp all skills-all rules-all subagents-all"
[[ -z "$NAME" && " $NO_NAME " != *" $TYPE "* ]] && usage "--skills/--rules/--subagents に名前を指定してください"
[[ -z "$FROM_RULESYNC" ]] && usage "--from を指定してください"

FROM_RULESYNC="${FROM_RULESYNC/#\~/$HOME}"
[[ ! -e "$FROM_RULESYNC" ]] && usage "コピー元パスが見つかりません: $FROM_RULESYNC"
if [[ -d "${FROM_RULESYNC}/.rulesync" ]]; then
  FROM_RULESYNC="${FROM_RULESYNC}/.rulesync"
else
  usage "$FROM_RULESYNC に .rulesync が見つかりません"
fi
FROM_RULESYNC="$(cd -P "$FROM_RULESYNC" && pwd)"

[[ -z "$TARGET" ]] && TARGET="$(get_workspace_root)"
[[ -z "$TARGET" ]] && usage "$(pwd) に .rulesync が見つかりません（ai-workspace で実行してください）"
TARGET="${TARGET/#\~/$HOME}"
TARGET="$(cd -P "$TARGET" && pwd)"
[[ ! -d "$TARGET" ]] && usage "インポート先ワークスペースが見つかりません: $TARGET"

RULESYNC="${TARGET}/.rulesync"
[[ ! -d "$RULESYNC" ]] && usage "$TARGET に .rulesync が見つかりません（ai-workspace で実行してください）"

do_skill() {
  local name="$1"
  local src="${FROM_RULESYNC}/skills/${name}"
  local dest="$RULESYNC/skills/${name}"
  local src_abs dest_abs
  src_abs="$(cd -P "$(dirname "$src")" 2>/dev/null && pwd)/$(basename "$src")"
  dest_abs="$(cd -P "$(dirname "$dest")" 2>/dev/null && pwd)/$(basename "$dest")"
  if [[ "$src_abs" == "$dest_abs" ]]; then
    echo "⏭️  同一パスのためスキップ: $dest"
    return 0
  fi
  if [[ -z "$FORCE" && -d "$dest" ]]; then
    echo "⏭️  スキップ（既存）: $dest"
    return 0
  fi
  if [[ -d "$src" ]]; then
    [[ -n "$FORCE" ]] && rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    cp -R "$src" "$dest"
    echo "✅ スキルをインポートしました: $name → $dest"
  elif [[ -f "$src" && "$(basename "$src")" == "SKILL.md" ]]; then
    [[ -n "$FORCE" ]] && rm -rf "$dest"
    mkdir -p "$dest"
    cp "$src" "$dest/SKILL.md"
    echo "✅ スキルをインポートしました（SKILL.md のみ）: $name → $dest/SKILL.md"
  else
    return 1
  fi
}

do_rule() {
  local name="$1"
  local src="${FROM_RULESYNC}/rules/${name}.md"
  local dest="$RULESYNC/rules/${name}.md"
  local src_abs dest_abs
  src_abs="$(cd -P "$(dirname "$src")" 2>/dev/null && pwd)/$(basename "$src")"
  dest_abs="$(cd -P "$(dirname "$dest")" 2>/dev/null && pwd)/$(basename "$dest")"
  if [[ "$src_abs" == "$dest_abs" ]]; then
    echo "⏭️  同一パスのためスキップ: $dest"
    return 0
  fi
  if [[ -z "$FORCE" && -f "$dest" ]]; then
    echo "⏭️  スキップ（既存）: $dest"
    return 0
  fi
  [[ ! -f "$src" ]] && usage "ルールのソースは .md ファイルを指定してください: $src"
  [[ -n "$FORCE" ]] && rm -f "$dest"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "✅ ルールをインポートしました: $name → $dest"
}

do_subagent() {
  local name="$1"
  local src="${FROM_RULESYNC}/subagents/${name}.md"
  local dest="$RULESYNC/subagents/${name}.md"
  local src_abs dest_abs
  src_abs="$(cd -P "$(dirname "$src")" 2>/dev/null && pwd)/$(basename "$src")"
  dest_abs="$(cd -P "$(dirname "$dest")" 2>/dev/null && pwd)/$(basename "$dest")"
  if [[ "$src_abs" == "$dest_abs" ]]; then
    echo "⏭️  同一パスのためスキップ: $dest"
    return 0
  fi
  if [[ -z "$FORCE" && -f "$dest" ]]; then
    echo "⏭️  スキップ（既存）: $dest"
    return 0
  fi
  [[ ! -f "$src" ]] && usage "サブエージェントのソースは .md ファイルを指定してください: $src"
  [[ -n "$FORCE" ]] && rm -f "$dest"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "✅ サブエージェントをインポートしました: $name → $dest"
}

do_mcp() {
  local src="${FROM_RULESYNC}/mcp.json.example"
  local dest="$RULESYNC/mcp.json.example"
  [[ ! -f "$src" ]] && usage "ソースが見つかりません: $src"
  local src_abs dest_abs
  src_abs="$(cd -P "$(dirname "$src")" 2>/dev/null && pwd)/$(basename "$src")"
  dest_abs="$(cd -P "$(dirname "$dest")" 2>/dev/null && pwd)/$(basename "$dest")"
  if [[ "$src_abs" == "$dest_abs" ]]; then
    echo "⏭️  同一ファイルのためスキップ: $dest"
    return 0
  fi
  if [[ -z "$FORCE" && -f "$dest" ]]; then
    echo "⏭️  スキップ（既存）: $dest"
    return 0
  fi
  cp -f "$src" "$dest"
  echo "✅ MCP設定をインポートしました: mcp.json.example → $dest"
}

run_all_skills() {
  shopt -s nullglob
  for path in "${FROM_RULESYNC}"/skills/*/; do
    [[ -d "$path" ]] || continue
    do_skill "$(basename "$path")"
  done
  shopt -u nullglob
}

run_all_rules() {
  shopt -s nullglob
  for path in "${FROM_RULESYNC}"/rules/*.md; do
    [[ -f "$path" ]] || continue
    do_rule "$(basename "$path" .md)"
  done
  shopt -u nullglob
}

run_all_subagents() {
  shopt -s nullglob
  for path in "${FROM_RULESYNC}"/subagents/*.md; do
    [[ -f "$path" ]] || continue
    do_subagent "$(basename "$path" .md)"
  done
  shopt -u nullglob
}

MODE="（既存スキップ）"; [[ -n "$FORCE" ]] && MODE="（上書き）"
echo "📥 インポート${MODE} | 種別: $TYPE | 名前: ${NAME:-—}"
echo "   コピー元: $FROM_RULESYNC"
echo "   インポート先: $TARGET"
echo ""

case "$TYPE" in
  skills)
    [[ ! -e "${FROM_RULESYNC}/skills/${NAME}" ]] && usage "ソースが見つかりません: ${FROM_RULESYNC}/skills/${NAME}"
    do_skill "$NAME"
    ;;
  skills-all)
    [[ ! -d "${FROM_RULESYNC}/skills" ]] && usage "コピー元に skills がありません: $FROM_RULESYNC"
    run_all_skills
    ;;
  rules)
    [[ ! -e "${FROM_RULESYNC}/rules/${NAME}.md" ]] && usage "ソースが見つかりません: ${FROM_RULESYNC}/rules/${NAME}.md"
    do_rule "$NAME"
    ;;
  rules-all)
    [[ ! -d "${FROM_RULESYNC}/rules" ]] && usage "コピー元に rules がありません: $FROM_RULESYNC"
    run_all_rules
    ;;
  subagents)
    [[ ! -e "${FROM_RULESYNC}/subagents/${NAME}.md" ]] && usage "ソースが見つかりません: ${FROM_RULESYNC}/subagents/${NAME}.md"
    do_subagent "$NAME"
    ;;
  subagents-all)
    [[ ! -d "${FROM_RULESYNC}/subagents" ]] && usage "コピー元に subagents がありません: $FROM_RULESYNC"
    run_all_subagents
    ;;
  mcp)
    [[ ! -f "${FROM_RULESYNC}/mcp.json.example" ]] && usage "ソースが見つかりません: ${FROM_RULESYNC}/mcp.json.example"
    do_mcp
    ;;
  all)
    [[ -d "${FROM_RULESYNC}/skills" ]] && run_all_skills
    [[ -d "${FROM_RULESYNC}/rules" ]] && run_all_rules
    [[ -d "${FROM_RULESYNC}/subagents" ]] && run_all_subagents
    [[ -f "${FROM_RULESYNC}/mcp.json.example" ]] && do_mcp
    ;;
  *)
    usage "無効な種別: $TYPE"
    ;;
esac
