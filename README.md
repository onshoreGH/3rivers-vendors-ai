# Onshore 3Rivers AI

Staff portal app for the 3Rivers logistics platform — authorized staff
sign in to see work orders, shipments, the supplier/vendor directory, the
communications inbox, and to start video check-ins with a supplier or
vendor.

Flutter (iOS + Android + macOS). Built on the shared `empowered-flutter`
template, carried over from `onshore-educate`; the shell (auth, nav,
AsyncView, theme) is vertical-neutral.

## Status

| Area | State |
|---|---|
| App structure, green theme, 5-tab nav, auth flow | ✅ done |
| Screens: Login, Dashboard, Work Orders (+detail), Shipments (+detail), Directory (+contact detail, start check-in), Settings, Delete account, Terms/Privacy | ✅ built (real screens, no placeholders) |
| Identity: `CFBundleDisplayName` = "Onshore 3Rivers AI", bundle id `ai.onshoretech.onshore-3rivers-ai`, `android:label`, category = business, encryption exempt | ✅ set |
| Mobile API (`/api/v1`) | 🟡 written (`api/mobile_v1.py`) — needs deploy: Keycloak client + nginx + main.py + service restart. See `api/3RIVERS_setup.txt`. |
| App icon | ⚠️ placeholder (still the Educate mark) — see `assets/branding/README.md` |
| Screenshots, walkthrough drive, signed build | ⬜ not done — do on the Mac after the API is live |

## Mobile API contract (`/api/v1`, JWT bearer, read-only for v1)

- `POST /auth/login` `{username,password}` → Keycloak ROPC (realm `onshoretech`, public client `3rivers-mobile`), returns `{access_token, refresh_token, expires_in, user}`
- `POST /auth/refresh` `{refresh_token}`
- `GET /me`
- `GET /dashboard` — counts (work orders, shipments, suppliers, vendors, overdue) + overdue samples
- `GET /work-orders?status=` , `GET /work-orders/{id}` (+ linked shipments)
- `GET /shipments?status=` , `GET /shipments/{id}` (+ linked work order)
- `GET /directory?kind=supplier|vendor` , `GET /directory/{type}/{id}` (+ session history)
- `GET /inbox` — email/SMS history (read-only)
- `POST /directory/{type}/{id}/check-in` — mint a host+guest video room, returns join URLs

## Building on the Mac

```bash
flutter pub get
dart run flutter_launcher_icons        # after replacing the placeholder icon
flutter run --dart-define=API_BASE_URL=https://3rivers.onshoretech.ai
```

## App Store notes

- Canonical ASC record: **App ID 6761303145**, bundle `ai.onshoretech.onshore-3rivers-ai`, name "Onshore 3rivers AI" (rename to "Onshore 3Rivers AI").
- Internal staff tool → **Unlisted App Distribution** (Guideline 3.2), same as Legal/Educate.
- No third-party AI. No file picker. Support/Privacy URLs: use `onshoresystems.ai/{support,privacy}`.
