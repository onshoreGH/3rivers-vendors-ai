#!/bin/bash
# Deploy the implemented mobile API controllers for the Vendors portal.
#
#   bash deploy-api-controllers.sh --dry-run
#   bash deploy-api-controllers.sh
#
# Replaces four 15-line stubs (index() returned a hardcoded empty array, the
# writers returned 'TODO') with real implementations backed by the repositories
# the browser portal already uses.
#
# NOT replaced, deliberately:
#   ExpenseController -- there is no ExpenseRepository and no expenses
#     collection anywhere in the app. Nothing to wire it to; writing one would
#     mean inventing a data source.
#   UserController -- admin-side user management, which the vendor mobile app
#     has no business exposing.
#
# Each file is syntax-checked with `php -l` BEFORE anything is moved into
# place, so a parse error cannot take the API down.
set -euo pipefail

APP=/srv/apps/3rivers-v/var/www/3riversv
DEST=$APP/app/Http/Controllers/Api
SRC="$(cd "$(dirname "$0")" && pwd)/controllers"
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP=/root/vendors-api-backups/controllers-$STAMP
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

FILES="InvoiceController.php PaymentController.php ProductController.php FinancialController.php"

echo "== 1. syntax-check the incoming files =="
for f in $FILES; do
  [ -f "$SRC/$f" ] || { echo "   !! missing $SRC/$f"; exit 1; }
  if php -l "$SRC/$f" > /dev/null 2>&1; then
    echo "   ok   $f"
  else
    echo "   FAIL $f"; php -l "$SRC/$f"; exit 1
  fi
done

if [ "$DRY" -eq 1 ]; then
  echo
  echo "== would back up to $BACKUP and install into $DEST =="
  for f in $FILES; do
    printf '   %-26s current: %s lines -> new: %s lines\n' \
      "$f" "$(wc -l < "$DEST/$f" 2>/dev/null || echo 0)" "$(wc -l < "$SRC/$f")"
  done
  echo "-- DRY RUN: nothing written --"
  exit 0
fi

echo "== 2. back up the stubs =="
mkdir -p "$BACKUP"
for f in $FILES; do
  [ -f "$DEST/$f" ] && cp -a "$DEST/$f" "$BACKUP/$f"
done
echo "   saved to $BACKUP"

echo "== 3. install =="
for f in $FILES; do
  install -o www-data -g www-data -m 0644 "$SRC/$f" "$DEST/$f"
  echo "   installed $f"
done

echo "== 4. clear caches =="
cd "$APP"
sudo -u www-data php artisan route:clear || php artisan route:clear
sudo -u www-data php artisan config:clear || true

echo "== 5. smoke-check that the app still boots =="
sudo -u www-data php artisan route:list --path=api/invoices > /dev/null && echo "   routes resolve"

echo
echo "Rollback: cp -a $BACKUP/*.php $DEST/ && cd $APP && sudo -u www-data php artisan route:clear"
