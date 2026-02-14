#!/usr/bin/env bash
# ntfy 通知送信スクリプト
# 使い方: bash scripts/ntfy.sh "メッセージ"
# 設定: config/settings.yaml に ntfy.server / ntfy.topic / (任意) ntfy.token を記載

set -e

# 第1引数チェック
MSG="${1:-}"
if [[ -z "$MSG" ]]; then
  echo "usage: $0 \"<message>\"" >&2
  exit 1
fi

# 設定ファイルパス（スクリプト基準でリポジトリルートの config/settings.yaml）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${SCRIPT_DIR}/../config/settings.yaml"

if [[ ! -f "$CONFIG" ]]; then
  echo "ntfy: config not found: $CONFIG" >&2
  exit 1
fi

# 設定読み取り（yq があれば使用、なければ grep/sed で簡易パース）
get_ntfy_val() {
  local key="$1"
  if command -v yq &>/dev/null; then
    yq -r ".ntfy.${key} // empty" "$CONFIG" 2>/dev/null || true
  else
    sed -n "/^ntfy:/,/^[^ ]/p" "$CONFIG" 2>/dev/null | grep -E "^\s*${key}:" | head -1 | sed -E 's/.*:\s*"?([^"]*)"?.*/\1/' | sed -E "s/^[[:space:]]+|[[:space:]]+$//g" || true
  fi
}

NTFY_SERVER="$(get_ntfy_val server)"
NTFY_TOPIC="$(get_ntfy_val topic)"
NTFY_TOKEN="$(get_ntfy_val token)"

NTFY_SERVER="${NTFY_SERVER:-https://ntfy.sh}"
if [[ -z "$NTFY_TOPIC" ]]; then
  echo "ntfy: ntfy.topic is required in $CONFIG" >&2
  exit 1
fi

# 末尾スラシュを除く
NTFY_SERVER="${NTFY_SERVER%/}"
URL="${NTFY_SERVER}/${NTFY_TOPIC}"

CURL_OPTS=(-sS -f -X POST -d "$MSG" "$URL")
if [[ -n "$NTFY_TOKEN" ]]; then
  CURL_OPTS=(-sS -f -X POST -H "Authorization: Bearer ${NTFY_TOKEN}" -d "$MSG" "$URL")
fi

if ! curl "${CURL_OPTS[@]}"; then
  echo "ntfy: failed to send (check network or $CONFIG)" >&2
  exit 1
fi

exit 0
