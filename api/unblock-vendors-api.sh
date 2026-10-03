#!/bin/bash
# Expose the 3Rivers Vendors mobile API (Sanctum bearer auth) from behind the
# oauth2-proxy SSO gate, and rate-limit the one route that becomes public.
#
# Run on onshore01 as root.  Idempotent; re-running is safe.
set -euo pipefail

VHOST=/etc/nginx/sites-enabled/3rivers-v.onshoretech.ai
APP=/srv/apps/3rivers-v/var/www/3riversv
API=$APP/routes/api.php
STAMP=$(date +%Y%m%d-%H%M%S)

echo "== 1. back up =="
# NOT into sites-enabled: nginx includes every file in that directory, so a
# .bak there becomes a live duplicate vhost.
mkdir -p /root/vendors-api-backups
cp -a "$VHOST" "/root/vendors-api-backups/3rivers-v.vhost.bak-$STAMP"
cp -a "$API"   "/root/vendors-api-backups/api.php.bak-$STAMP"
echo "   saved to /root/vendors-api-backups/"

echo "== 2. rate-limit the login route (it is about to become public) =="
if grep -q "throttle:10,1" "$API"; then
  echo "   already throttled, leaving alone"
else
  python3 - "$API" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
old = "Route::post('/auth/login', [AuthController::class, 'login']);"
new = "Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');"
if old not in s:
    sys.exit("!! could not find the un-throttled login route - aborting, nothing changed")
open(p, 'w').write(s.replace(old, new, 1))
print("   added throttle:10,1 to /auth/login")
PY
  chown www-data:www-data "$API"
fi

echo "== 3. add the /api/ location (no auth_request) =="
if grep -q "location \^~ /api/" "$VHOST"; then
  echo "   already present, leaving alone"
else
  python3 - "$VHOST" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
anchor = "    location / {"
if anchor not in s:
    sys.exit("!! could not find 'location / {' - aborting, nothing changed")

block = """    # Mobile API: these routes authenticate themselves with Sanctum bearer
    # tokens (everything except /api/auth/login carries auth:sanctum), so they
    # must NOT sit behind the oauth2-proxy SSO gate -- a mobile client cannot
    # follow a browser redirect to Keycloak, which is why every call returned
    # 302. Handled inline rather than via try_files, because falling through to
    # `location ~ \\.php$` would re-apply auth_request and 302 again.
    location ^~ /api/ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root/index.php;
        fastcgi_param SCRIPT_NAME     /index.php;
        fastcgi_param HTTPS           on;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

"""
open(p, 'w').write(s.replace(anchor, block + anchor, 1))
print("   inserted location ^~ /api/ ahead of location /")
PY
fi

echo "== 4. clear Laravel's route cache (edits to api.php are inert while cached) =="
cd "$APP"
sudo -u www-data php artisan route:clear || php artisan route:clear

echo "== 5. validate and reload nginx =="
nginx -t
systemctl reload nginx
echo "   reloaded"

echo "== 6. verify =="
# Accept: application/json is NOT optional here. Laravel's Authenticate
# middleware REDIRECTS (302) instead of returning 401/422 unless the request
# expectsJson(), so probing without this header makes a correctly deployed
# API look like it is still behind the SSO gate. That false negative cost a
# round of debugging the first time.
JSON=(-H "Accept: application/json" -H "Content-Type: application/json")
printf '   unauthenticated /api/me (want 401): '
curl -s -o /dev/null -m 12 "${JSON[@]}" -w '%{http_code}\n' https://3rivers-v.onshoretech.ai/api/me
printf '   bad login               (want 422): '
curl -s -o /dev/null -m 12 "${JSON[@]}" -X POST https://3rivers-v.onshoretech.ai/api/auth/login \
  -d '{"login":"nobody@example.com","password":"wrong","device_name":"probe"}' \
  -w '%{http_code}\n'
printf '   browser root STILL SSO-gated (want 302): '
curl -s -o /dev/null -m 12 -w '%{http_code}\n' https://3rivers-v.onshoretech.ai/

echo
echo "Rollback: cp /root/vendors-api-backups/3rivers-v.vhost.bak-$STAMP $VHOST && cp /root/vendors-api-backups/api.php.bak-$STAMP $API && nginx -t && systemctl reload nginx"
