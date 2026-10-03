#!/bin/bash
# Fix per-action permissions on the Vendors API resource routes.
#
#   cd /srv/apps/3rivers-v/var/www/3riversv
#   bash fix-resource-permissions.sh --dry-run
#   bash fix-resource-permissions.sh
#
# THE BUG: routes/api.php registers each apiResource like
#
#   Route::apiResource('invoices', InvoiceController::class)
#       ->middleware(['index' => 'permission:api.invoices.read',
#                     'store' => 'permission:api.invoices.write', ...]);
#
# ->middleware() does not take an action=>middleware map. Laravel discards the
# keys and applies every value to every route in the resource, so today
# `GET /api/invoices` demands read AND write AND delete simultaneously --
# confirmed with `php artisan route:list --path=api/invoices -v`.
#
# The effect is fail-CLOSED, not fail-open: nothing is over-permitted, but any
# read-only vendor is locked out of listing invoices, expenses, payments and
# products. Only owner/admin get through, because RequirePermission
# short-circuits for those roles and masks the whole problem.
#
# THE FIX: ->middlewareFor(), which does take per-action mappings and exists in
# this Laravel (11.51; verified present in PendingResourceRegistration).
#
# This LOOSENS the GET routes to what was always intended. Read it before you
# run it.
set -euo pipefail

APP=/srv/apps/3rivers-v/var/www/3riversv
API=$APP/routes/api.php
STAMP=$(date +%Y%m%d-%H%M%S)
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

[ -f "$API" ] || { echo "missing $API"; exit 1; }

if [ "$DRY" -eq 0 ]; then
  mkdir -p /root/vendors-api-backups
  cp -a "$API" "/root/vendors-api-backups/api.php.bak-resperm-$STAMP"
  echo "backed up -> /root/vendors-api-backups/api.php.bak-resperm-$STAMP"
fi

python3 - "$API" "$DRY" <<'PY'
import re, sys
path, dry = sys.argv[1], sys.argv[2] == "1"
src = open(path).read()
out = src
changed = []

# Each apiResource block: capture the resource name, the controller
# expression, and the whole ->middleware([...]); tail.
pattern = re.compile(
    r"(Route::apiResource\(\s*'(?P<res>[a-z]+)'\s*,\s*(?P<ctrl>[^)]+?)\s*\)\s*)"
    r"->middleware\(\s*\[(?P<map>.*?)\]\s*\)\s*;",
    re.S,
)

def build(m):
    res, head, ctrl = m.group('res'), m.group(1), m.group('ctrl')
    body = m.group('map')
    # pull the permission key actually named for each action
    got = dict(re.findall(r"'(\w+)'\s*=>\s*'permission:([\w.]+)'", body))
    read = got.get('index') or got.get('show')
    write = got.get('store') or got.get('update')
    delete = got.get('destroy')
    if not (read and write and delete):
        return m.group(0)  # unfamiliar shape - leave it alone
    changed.append(res)
    return (
        f"{head}\n"
        f"        ->middlewareFor(['index', 'show'], 'permission:{read}')\n"
        f"        ->middlewareFor(['store', 'update'], 'permission:{write}')\n"
        f"        ->middlewareFor('destroy', 'permission:{delete}');"
    )

out = pattern.sub(build, out)

if not changed:
    sys.exit("!! no resource blocks matched - nothing changed, investigate by hand")

print("   rewrote:", ", ".join(changed))
if dry:
    print("   -- DRY RUN: not written --")
else:
    open(path, 'w').write(out)
    print("   written")
PY

if [ "$DRY" -eq 1 ]; then
  echo "dry run complete"
  exit 0
fi

chown www-data:www-data "$API"
cd "$APP"
echo "== clear route cache (edits to api.php are inert while cached) =="
sudo -u www-data php artisan route:clear || php artisan route:clear

echo "== verify: GET /api/invoices should now require ONLY read =="
php artisan route:list --path=api/invoices -v 2>/dev/null | head -6

echo
echo "Rollback: cp /root/vendors-api-backups/api.php.bak-resperm-$STAMP $API && cd $APP && sudo -u www-data php artisan route:clear"
