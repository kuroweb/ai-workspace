#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  echo "Usage: $(basename "$0") --src <path> [--dry-run]"
  echo ""
  echo "Options:"
  echo "  --src <path>    インポート元のパス（必須）"
  echo "  --dry-run       実際には変更せず確認のみ"
  exit 1
}

SRC=""
DRY_RUN=""

while [ $# -gt 0 ]; do
  case "$1" in
    --src)     SRC="$2"; shift 2 ;;
    --dry-run) DRY_RUN="--dry-run"; shift ;;
    *) usage ;;
  esac
done

if [ -z "$SRC" ]; then
  echo "Error: --src が指定されていません"
  usage
fi

if [ ! -d "$SRC" ]; then
  echo "Error: インポート元が存在しません: $SRC"
  exit 1
fi

IGNORE_FILE="$PROJECT_ROOT/.syncignore"
BACKUP_DIR="$SCRIPT_DIR/backup/$(date +%Y%m%d%H%M%S)"

echo "インポート元: $SRC"
echo "インポート先: $PROJECT_ROOT"
if [ -n "$DRY_RUN" ]; then
  echo "[dry-run] 実際には変更しません"
fi
echo ""

# バックアップ
if [ -z "$DRY_RUN" ]; then
  echo "バックアップ: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  cp -R "$PROJECT_ROOT" "$BACKUP_DIR"
  echo ""
fi

RSYNC_OPTS="-av --delete"
if [ -f "$IGNORE_FILE" ]; then
  echo "無視ファイル: $IGNORE_FILE"
  RSYNC_OPTS="$RSYNC_OPTS --exclude-from=$IGNORE_FILE"
else
  echo "無視ファイルなし: $IGNORE_FILE が見つかりません（スキップ）"
fi
echo ""

# shellcheck disable=SC2086
rsync $RSYNC_OPTS $DRY_RUN "$SRC/" "$PROJECT_ROOT/"
