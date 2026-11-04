#!/bin/sh
# Публикует содержимое текущей папки в public_html на Beget по FTP.
# Перед первым запуском: cp .ftp-credentials.example .ftp-credentials и заполнить данными.
#
# Использование:
#   ./deploy.sh          — пробный запуск (dry-run), ничего не меняет на сервере
#   ./deploy.sh --apply  — реальная загрузка файлов
#
# Файлы на сервере никогда не удаляются (mirror без --delete).

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CREDENTIALS_FILE="$SCRIPT_DIR/.ftp-credentials"

if [ ! -f "$CREDENTIALS_FILE" ]; then
  echo "Не найден $CREDENTIALS_FILE. Скопируйте .ftp-credentials.example в .ftp-credentials и заполните его." >&2
  exit 1
fi

. "$CREDENTIALS_FILE"

EXCLUDES="--exclude-glob .git/ --exclude-glob .gitignore --exclude-glob .DS_Store --exclude-glob .ftp-credentials* --exclude-glob deploy.sh --exclude-glob CLAUDE.md --exclude-glob .claude/ --exclude-glob *.md"

MODE="dry-run"
if [ "${1:-}" = "--apply" ]; then
  MODE="apply"
fi

if [ "$MODE" = "dry-run" ]; then
  echo "=== ПРОБНЫЙ ЗАПУСК (ничего не загружается и не меняется на сервере) ==="
  lftp -u "$FTP_USER","$FTP_PASS" "ftp://$FTP_HOST:$FTP_PORT" <<EOF
set ftp:ssl-allow no
mirror --reverse --dry-run --verbose $EXCLUDES "$SCRIPT_DIR" "$FTP_REMOTE_DIR"
bye
EOF
  echo "=== Это был пробный запуск. Для реальной загрузки: ./deploy.sh --apply ==="
else
  lftp -u "$FTP_USER","$FTP_PASS" "ftp://$FTP_HOST:$FTP_PORT" <<EOF
set ftp:ssl-allow no
mirror --reverse --verbose $EXCLUDES "$SCRIPT_DIR" "$FTP_REMOTE_DIR"
bye
EOF
fi
