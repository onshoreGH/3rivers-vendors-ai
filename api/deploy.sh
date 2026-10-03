#!/usr/bin/env bash
# Deploy the 3Rivers mobile API. Run on onshore01 (10.0.0.71) as root.
# Safe to re-run — each step checks before patching.
#
# FIRST copy the router into place (from onshore03, or scp this repo's api/):
#   scp mobile_v1.py root@10.0.0.71:/opt/3rivers/app/mobile_v1.py
#
set -euo pipefail

APP=/opt/3rivers/app
NGINX=/etc/nginx/conf.d/3rivers.onshoretech.ai.conf
TS=$(date +%Y%m%d-%H%M%S)

echo "== 1. mobile_v1.py present + valid =="
test -f "$APP/mobile_v1.py" || { echo "  MISSING — scp it to $APP/mobile_v1.py first"; exit 1; }
chown three_rivers:three_rivers "$APP/mobile_v1.py"
"$APP/venv/bin/python" -c "import ast,sys; ast.parse(open('$APP/mobile_v1.py').read()); print('  syntax OK')"

echo "== 2. venv deps =="
"$APP/venv/bin/python" -c "import jwt, cryptography" 2>/dev/null && echo "  PyJWT+crypto ok" \
  || "$APP/venv/bin/pip" install --quiet "PyJWT[crypto]"

echo "== 3. wire router into main.py =="
if grep -q mobile_v1_router "$APP/main.py"; then
  echo "  already wired"
else
  cp "$APP/main.py" "$APP/main.py.bak-mobilev1-$TS"
  {
    printf '\n\n# --- mobile app API (own JWT bearer verify, NOT behind oauth2-proxy) ---\n'
    printf 'from mobile_v1 import router as mobile_v1_router  # noqa: E402\n'
    printf 'app.include_router(mobile_v1_router)\n'
  } >> "$APP/main.py"
  echo "  appended (backup: main.py.bak-mobilev1-$TS)"
fi

echo "== 4. nginx: add /api/v1/ bypass (no oauth2) =="
if grep -q 'location \^~ /api/v1/' "$NGINX"; then
  echo "  already present"
else
  cp "$NGINX" "$NGINX.bak-mobilev1-$TS"
  awk '
    /^[[:space:]]*location \/api\/ \{/ && !done {
      print "  location ^~ /api/v1/ {"
      print "    proxy_pass http://127.0.0.1:9000;"
      print "    proxy_http_version 1.1;"
      print "    proxy_set_header Host              $host;"
      print "    proxy_set_header X-Real-IP         $remote_addr;"
      print "    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;"
      print "    proxy_set_header X-Forwarded-Proto $scheme;"
      print "    proxy_read_timeout 60;"
      print "  }"
      print ""
      done=1
    }
    { print }
  ' "$NGINX.bak-mobilev1-$TS" > "$NGINX"
  echo "  inserted (backup: $NGINX.bak-mobilev1-$TS)"
fi

echo "== 5. nginx test + reload =="
nginx -t
systemctl reload nginx

echo "== 6. restart API =="
systemctl restart 3rivers-api
sleep 2
echo "  active: $(systemctl is-active 3rivers-api)"
journalctl -u 3rivers-api -n 20 --no-pager | tail -20

echo "== 7. smoke: no-auth /api/v1 must be 401 (NOT 302 to /oauth2) =="
curl -s -o /dev/null -w "  /api/v1/dashboard -> %{http_code}\n" https://3rivers.onshoretech.ai/api/v1/dashboard

cat <<'NEXT'

--- Next: create Keycloak client (realm onshoretech):
    Clients -> Create -> id: 3rivers-mobile, public, Direct access grants ON.
    Then verify end-to-end (USER/PASS = a 3Rivers staff Keycloak account):

  TOK=$(curl -s -d 'grant_type=password&client_id=3rivers-mobile&username=USER&password=PASS&scope=openid' \
    https://auth.onshoresystems.ai/realms/onshoretech/protocol/openid-connect/token \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')
  curl -s https://3rivers.onshoretech.ai/api/v1/me          -H "Authorization: Bearer $TOK"
  curl -s https://3rivers.onshoretech.ai/api/v1/dashboard   -H "Authorization: Bearer $TOK"
  curl -s https://3rivers.onshoretech.ai/api/v1/work-orders -H "Authorization: Bearer $TOK" | head -c 300
NEXT
