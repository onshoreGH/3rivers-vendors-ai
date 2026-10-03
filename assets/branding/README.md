# Branding — Onshore 3Rivers

**TODO (do on the Mac before the first store build):** the icon files here
are still the Educate mark (white mortarboard on teal). Replace with a
3Rivers mark — a simple white "3R" or three-rivers/waves glyph on
logistics green (`#1FA463`). Then regenerate the platform icon sets:

    dart run flutter_launcher_icons

- `icon_source.png` — 1024px, no alpha (iOS). `icon_foreground.png` —
  Android adaptive foreground (safe zone ~66%).
- Source SVGs are rasterized with `qlmanage -t -s 1024` (no ImageMagick on
  the box) — see how the Legal/Educate icons were made.
- `logo_mark.png` is unused; delete once the real icon is in.
