#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ ! -f "$PROJECT_ROOT/.env" ]; then
  echo "Error: .env file not found in $PROJECT_ROOT" >&2
  exit 1
fi

# .envファイルからトークンを読み込む
source "$PROJECT_ROOT/.env"

docker run --rm -i \
  -e ESA_ACCESS_TOKEN="$ESA_ACCESS_TOKEN" \
  -e ESA_TEAM_NAME="xxx" \
  ghcr.io/esaio/esa-mcp-server
