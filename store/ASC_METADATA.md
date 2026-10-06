# App Store Connect metadata — Onshore 3Rivers Vendors

App ID **6760920784** · bundle `ai.onshoretech.3riversv` · build **1.0.0 (3)**, VALID

Everything below is paste-ready. Character counts are against Apple's limits.

---

## App Information

**Name** (30) — already set
```
Onshore 3Rivers Vendors
```

**Subtitle** (30)
```
Supplier invoices & notices
```

**Primary category:** Business
**Secondary category:** Productivity

**Content rights:** does not contain, show, or access third-party content
**Age rating:** 4+ — no objectionable content of any kind

---

## Version Information

**Promotional text** (170) — editable without a new version
```
Track invoices, payments and catalogue items, and read notices from 3Rivers, from the floor or the road.
```

**Description** (4000)
```
Onshore 3Rivers Vendors gives approved 3Rivers suppliers a direct view of their account.

INVOICES
See every invoice raised against your account with its amount, due date and payment status. Settled invoices are marked paid; anything past its terms is flagged so nothing is missed. Filter to past due when you need to act.

OVERVIEW
Revenue received to date, invoice and payment counts, and a month-by-month view of payments so you can see the trend rather than a single number.

CATALOGUE
Browse the items on your account with SKU, description, unit of measure, price and quantity on hand. Search by name or SKU, and include or exclude discontinued items.

NOTICES
Operational announcements from 3Rivers — purchase order schedules, packing slip requirements, dock closures, insurance certificate renewals and payment runs. Tap to read in full; the app records what you have read.

ACCESS
Accounts are created by a 3Rivers administrator. There is no public sign-up. If you supply 3Rivers and need access, contact your 3Rivers representative.

Support: support@onshoretech.ai
```

**Keywords** (100, comma-separated, no spaces after commas)
```
supplier,vendor,invoice,procurement,purchase order,catalogue,manufacturing,b2b,portal,payments
```

**Support URL**
```
https://onshoresystems.ai/support
```

**Marketing URL**
```
https://www.onshoresystems.ai
```

**Copyright** — match the legal entity, not the trading name
```
2026 Onshore Technology Consultants LLC
```

---

## App Review Information

**Sign-in required:** Yes

| | |
|---|---|
| User name | `appreview@onshoretech.ai` |
| Password | `OnshoreApp2026` |

Verified live against `https://3rivers-v.onshoretech.ai/api/auth/login`: returns a token, and every screen the app uses returns content — 10 invoices, 11 catalogue items, 7 notices, revenue $24,770.25 across five months. The account holds a purpose-built read-only role, so it cannot alter or delete any data.

**Notes**
```
Sign in with the credentials above.

The app is a supplier portal for approved vendors of 3Rivers, a manufacturer. Four screens: Overview shows revenue received and payments by month; Invoices lists invoices with amounts, due dates and payment status; Catalogue lists stocked items with SKU, price and quantity; Notices holds operational announcements from 3Rivers, which can be opened and are marked read.

DISTRIBUTION: this app is intended for a specific business and its approved suppliers, not a general public audience. We have requested Unlisted App Distribution and will distribute by direct link only. Accounts cannot be self-registered: a 3Rivers administrator provisions each supplier individually. There is no browsing, trial or guest mode, and no feature is available without credentials.

ARTIFICIAL INTELLIGENCE: the app uses no third-party AI service. No user data is sent to any AI provider. All traffic goes over TLS to our own backend only.

IN-APP PURCHASE: none. There is no subscription and no paid content. No user pays for anything inside the app.
```

---

## Guideline 3.2 answers

Same position as Onshore 3rivers AI, and it applies more cleanly here.

1. **Restricted to a single company or organization?** Yes. Access is limited to approved suppliers of 3Rivers and their named staff.
2. **Designed for a limited or specific group of companies?** Yes. It serves 3Rivers' supplier base. Another manufacturer could become a client of Onshore Technology Consultants under a commercial agreement, and its suppliers would then be provisioned individually.
3. **Features intended for the general public?** None. Every screen requires an account created by an administrator. There is no browsing, trial, guest or demo mode.
4. **How do users obtain an account?** They cannot self-register. A 3Rivers administrator requests the account; we provision it and credentials are issued to the named supplier contact.
5. **Paid content, and who pays?** None. No in-app purchase, no subscription, no user-paid features.

**Also file the request:** developer.apple.com/contact/request/unlisted-app-distribution, for bundle `ai.onshoretech.3riversv`. A written reply does not substitute for it.

---

## Screenshots

Staged on the Mac at `~/Desktop/vendors-screenshots-FINAL/`.

| Slot | Files | Size |
|---|---|---|
| iPhone 6.5" | 7 | 1284 × 2778 |
| iPad 12.9" | 7 | 2048 × 2732 |

Apple uses the **first three** on the install sheet, so order them:

1. `02-overview.png` — revenue and the monthly chart, the strongest single frame
2. `03-invoices.png` — paid/past-due statuses
3. `04-catalogue.png` — real SKUs and stock
4. `05-notices.png`
5. `07-notice-detail.png`
6. `06-settings.png`

`01-signed-in.png` duplicates the overview; leave it out unless a seventh is wanted.

---

## Before submitting

- [ ] Attach build **1.0.0 (3)**
- [ ] **Replace the launch screen** — still Flutter's default placeholder, and it is the first thing a reviewer sees. Placeholder assets are what drew the 2.1(a) rejection on the contractor's app_legal. Drop a branded image into `ios/Runner/Assets.xcassets/LaunchImage.imageset/`.
- [ ] File the Unlisted App Distribution request
- [ ] Confirm pricing — free, unless this carries a licence fee like the other verticals

**Known non-blocking warning:** deployment target is iOS 14.0. Apple refuses uploads below 15.0 from April 2027. It affects every app in this family, so it is worth one coordinated bump rather than five deadline fixes.
