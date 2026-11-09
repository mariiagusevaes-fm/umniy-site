#!/bin/sh
# Публикует содержимое текущей папки на GitHub Pages (umniy-site.ru).
# Пересобирает "чистые" адреса (папка/index.html) из плоских .html файлов
# и кладёт их в соседнее git-воркдерево ветки gh-pages.
#
# Использование:
#   ./deploy-github.sh          — пробный запуск (dry-run), показывает что изменится
#   ./deploy-github.sh --apply  — реальная публикация (commit + push main и gh-pages)

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKTREE="$SCRIPT_DIR/../umniy-site-gh-pages-worktree"

if [ ! -d "$WORKTREE" ]; then
  echo "Не найдено воркдерево $WORKTREE. Нужно один раз создать: git worktree add ../umniy-site-gh-pages-worktree origin/gh-pages -B gh-pages" >&2
  exit 1
fi

MODE="dry-run"
if [ "${1:-}" = "--apply" ]; then
  MODE="apply"
fi

echo "=== Обновляю воркдерево gh-pages из origin ==="
(cd "$WORKTREE" && git fetch origin gh-pages -q && git reset --hard origin/gh-pages -q)

echo "=== Пересобираю структуру с чистыми URL ==="
# Очищаем старые сгенерированные файлы (кроме .git)
find "$WORKTREE" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

# Копируем всё, кроме служебных файлов
rsync -a --exclude='.git' --exclude='.ftp-credentials*' --exclude='.DS_Store' \
  --exclude='deploy.sh' --exclude='deploy-github.sh' --exclude='SEO-аудит.md' \
  --exclude='.gitignore' \
  "$SCRIPT_DIR/" "$WORKTREE/"

cd "$WORKTREE"
for f in *.html; do
  if [ "$f" != "index.html" ]; then
    name="${f%.html}"
    mkdir -p "$name"
    title="$(grep -o '<title>[^<]*</title>' "$f" | head -1 | sed 's/<[^>]*>//g')"
    mv "$f" "$name/index.html"
    # GitHub Pages не умеет server-side редиректы (.htaccess не работает) —
    # оставляем на старом .html-адресе статическую заглушку с мгновенным
    # meta-refresh и canonical на чистый адрес, чтобы Google не получал 404
    # по старым индексированным .html-ссылкам.
    cat > "$f" <<STUB
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="robots" content="noindex">
<link rel="canonical" href="https://umniy-site.ru/$name">
<meta http-equiv="refresh" content="0; url=/$name">
<title>${title:-Страница перемещена}</title>
</head>
<body>
<p>Эта страница переехала на <a href="/$name">umniy-site.ru/$name</a>.</p>
</body>
</html>
STUB
  fi
done

# Абсолютный путь к favicon для страниц, переехавших в подпапки
find . -mindepth 2 -name "index.html" -exec sed -i '' 's|href="favicon.png"|href="/favicon.png"|g' {} \;

touch .nojekyll
echo "umniy-site.ru" > CNAME

git add -A

if [ "$MODE" = "dry-run" ]; then
  echo ""
  echo "=== ПРОБНЫЙ ЗАПУСК — изменения, которые будут опубликованы ==="
  git status --short
  git reset -q
  echo ""
  echo "=== Это был пробный запуск. Для реальной публикации: ./deploy-github.sh --apply ==="
else
  if git diff --cached --quiet; then
    echo "Изменений нет — публиковать нечего."
  else
    git commit -q -m "Обновление сайта: $(date '+%Y-%m-%d %H:%M')"
    git push origin gh-pages
    echo "=== Опубликовано на GitHub Pages ==="
  fi
  echo ""
  echo "=== Синхронизирую исходники (ветка main) ==="
  cd "$SCRIPT_DIR"
  git add -A
  if git diff --cached --quiet; then
    echo "В main изменений нет."
  else
    git commit -q -m "Обновление исходников: $(date '+%Y-%m-%d %H:%M')"
    git push origin main
    echo "=== main обновлён ==="
  fi
fi
