<?php
/**
 * Seed a presentable vendor dataset for the 3Rivers Vendors mobile app.
 *
 *   cd /srv/apps/3rivers-v/var/www/3riversv
 *   sudo -u www-data php seed-vendor-demo.php --dry-run
 *   sudo -u www-data php seed-vendor-demo.php
 *   sudo -u www-data php seed-vendor-demo.php --prune      # also hide test litter
 *
 * WHY: the live data is one invoice for "Admin Test", one $99 cash payment,
 * products called "Widget B" and "Old Item", and broadcasts reading "Sat Test"
 * and "Sound Test". That is what an App Store reviewer would see, and visible
 * placeholder content is what drew the Legal app's 2.1 rejection.
 *
 * ADDITIVE BY DEFAULT. Unlike the Legal seeder, nothing here is scoped to a
 * single demo client -- these collections are shared, so a blind wipe would
 * destroy whatever real records exist alongside the test ones. --prune
 * soft-deletes ONLY records whose text matches the known test markers below,
 * and --dry-run prints exactly which ids that would be, to be read before it
 * is trusted.
 *
 * Idempotent: seeded rows carry a marker field, and a second run without
 * --force reports what already exists instead of duplicating it.
 */

use App\Repositories\BroadcastRepository;
use Illuminate\Support\Facades\DB;
use App\Repositories\InvoiceRepository;
use App\Repositories\PaymentRepository;
use App\Repositories\ProductRepository;

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$dry = in_array('--dry-run', $argv, true);
$prune = in_array('--prune', $argv, true);
$force = in_array('--force', $argv, true);

/** Rows this script created carry this, so re-runs can recognise their own work. */
const MARKER = 'seed:vendor-demo';

/** Text that identifies the pre-existing scratch records. Matched case-insensitively. */
const TEST_MARKERS = [
    'admin test', 'this is a test', 'sat test', 'sound test', 'testing from kc',
    'widget b', 'widget a', 'old item', 'discontinued item',
];

$say = static fn (string $m) => print("   $m\n");
$invoices = app(InvoiceRepository::class);
$payments = app(PaymentRepository::class);
$products = app(ProductRepository::class);
$broadcasts = app(BroadcastRepository::class);

// --------------------------------------------------------------------------
// The dataset. Dates are relative to today so the app never looks stale, and
// payments carry an explicit paid_on -- create() overwrites created_at with
// now(), so without paid_on every payment would land in the current month and
// the financial chart would be a single bar.
// --------------------------------------------------------------------------
$today = new DateTimeImmutable('today');
$d = static fn (int $days) => $today->modify(($days >= 0 ? '+' : '') . $days . ' days')->format('Y-m-d');
$dt = static fn (int $days) => $today->modify(($days >= 0 ? '+' : '') . $days . ' days')->format('Y-m-d H:i:s');

$CUSTOMER = ['name' => 'Cedar Ridge Manufacturing', 'email' => 'ap@cedarridgemfg.com'];

/** [number, days_until_due, amount, paid?] */
$INVOICE_PLAN = [
    ['INV-2026-0142', -118, 4820.00, true],
    ['INV-2026-0157', -96,  2140.50, true],
    ['INV-2026-0163', -74,  7310.00, true],
    ['INV-2026-0178', -51,  1295.75, true],
    ['INV-2026-0184', -34,  5680.00, true],
    ['INV-2026-0196', -19,  3425.00, true],
    ['INV-2026-0203', -9,   2890.25, false],  // overdue, unpaid
    ['INV-2026-0211', 6,    6150.00, false],  // due soon
    ['INV-2026-0218', 17,   1740.00, false],
    ['INV-2026-0224', 29,   9320.50, false],
];

$PRODUCTS = [
    ['CRM-1010', 'Hydraulic Coupler, 1/2 in NPT',   'Zinc-plated steel quick-connect coupler.',        48.75,  320, 'EA', 'ACTIVE'],
    ['CRM-1024', 'Hydraulic Hose, 3/8 in x 10 ft',  'Two-wire braid, 4000 PSI working pressure.',      86.40,  145, 'EA', 'ACTIVE'],
    ['CRM-1038', 'Bearing Assembly, 60 mm',         'Sealed double-row, pre-greased.',                212.00,   62, 'EA', 'ACTIVE'],
    ['CRM-1052', 'Drive Belt, B-Section 54 in',     'Wrapped V-belt for industrial drives.',           31.20,  410, 'EA', 'ACTIVE'],
    ['CRM-1067', 'Industrial Lubricant, 5 gal',     'ISO 68 anti-wear hydraulic oil.',                139.95,   88, 'PL', 'ACTIVE'],
    ['CRM-1071', 'Safety Gloves, Cut Level A4',     'Nitrile-coated, touchscreen compatible.',         18.50, 1240, 'PR', 'ACTIVE'],
    ['CRM-1085', 'Pressure Gauge, 0-5000 PSI',      'Glycerin-filled, 2.5 in stainless face.',         64.00,  176, 'EA', 'ACTIVE'],
    ['CRM-1093', 'Weld Wire, ER70S-6 .035 in',      '33 lb spool, mild steel MIG wire.',               97.80,  210, 'SP', 'ACTIVE'],
    ['CRM-0914', 'Hydraulic Coupler, 3/8 in NPT',   'Superseded by CRM-1010.',                         44.10,    0, 'EA', 'INACTIVE'],
];

$BROADCASTS = [
    ['Q3 purchase order schedule published',
     'Purchase orders for the July-September window are now in the portal. Please acknowledge receipt of each PO within five business days so scheduling can confirm dock times.', -42],
    ['Updated packing slip requirements',
     'All inbound shipments must include the PO number on the outside of the carton as of the first of next month. Shipments without it will be held at receiving and may delay payment.', -28],
    ['Invoice submission moving to the portal',
     'Emailed invoices will no longer be processed after the end of the quarter. Submit invoices through the Invoices section of this app or the vendor portal to avoid payment delays.', -21],
    ['Receiving dock closed for maintenance',
     'The north receiving dock will be closed Friday for scheduled maintenance. Deliveries that day should be routed to the south dock. Gate access codes are unchanged.', -12],
    ['Annual insurance certificates due',
     'Certificates of insurance expire at the end of next month. Please upload current certificates naming 3Rivers as additional insured to keep your vendor status active.', -6],
    ['Payment run completed',
     'This week\'s payment run has been released. Remittance details are available against each invoice in the Invoices section.', -2],
];

// --------------------------------------------------------------------------
echo "== existing data ==\n";
$existingInvoices = $invoices->search('', 500);
$existingProducts = $products->allSortedBySku();
$existingPayments = $payments->recent(500);
$existingBroadcasts = $broadcasts->recent(500);
$say(sprintf(
    'invoices=%d  payments=%d  products=%d  broadcasts=%d',
    $existingInvoices->total(), count($existingPayments), count($existingProducts), count($existingBroadcasts),
));

$alreadySeeded = 0;
foreach ($existingInvoices->items() as $row) {
    if ((($row->source ?? null) === MARKER)) {
        $alreadySeeded++;
    }
}
// Skip the INSERT step when a set is already present, but still run the prune
// below -- --prune and seeding are independent operations.
//
// This previously exited early only when --prune was absent, which meant
// `--prune` on an already-seeded database pruned AND then inserted a second
// full set. Two duplicate batches were created that way before it was caught.
$skipSeed = $alreadySeeded > 0 && !$force;
if ($skipSeed) {
    $say("!! $alreadySeeded seeded invoices already present - skipping insert (use --force to add another set)");
}

// --------------------------------------------------------------------------
echo "== test litter " . ($prune ? "(will be hidden)" : "(use --prune to hide)") . " ==\n";
$matches = static function (array $haystacks): bool {
    foreach ($haystacks as $h) {
        foreach (TEST_MARKERS as $needle) {
            if ($h !== null && str_contains(mb_strtolower((string) $h), $needle)) {
                return true;
            }
        }
    }
    return false;
};

$toPrune = ['invoices' => [], 'products' => [], 'broadcasts' => []];
foreach ($existingInvoices->items() as $r) {
    if ($matches([$r->customer_name ?? null, $r->number ?? null])) {
        $toPrune['invoices'][] = (int) $r->id;
    }
}
foreach ($existingProducts as $r) {
    if ($matches([$r['name'] ?? null, $r['description'] ?? null])) {
        $toPrune['products'][] = (int) $r['id'];
    }
}
foreach ($existingBroadcasts as $r) {
    if ($matches([$r['title'] ?? null, $r['message'] ?? null])) {
        $toPrune['broadcasts'][] = (int) $r['id'];
    }
}
foreach ($toPrune as $kind => $ids) {
    $say(sprintf('%-11s %s', $kind, $ids === [] ? '(none matched)' : implode(', ', $ids)));
}

if ($prune && !$dry) {
    foreach ($toPrune['invoices'] as $id)   { $invoices->softDelete($id); }
    foreach ($toPrune['products'] as $id)   { $products->softDelete($id); }
    foreach ($toPrune['broadcasts'] as $id) { $broadcasts->softDelete($id); }
    $say('pruned');
}

// --------------------------------------------------------------------------
echo "== seed ==\n";
if ($skipSeed) {
    $say('skipped (already seeded)');
    echo "\n== done ==\n";
    exit(0);
}
if ($dry) {
    $say(sprintf(
        'would insert %d invoices (%d with payments), %d products, %d broadcasts',
        count($INVOICE_PLAN),
        count(array_filter($INVOICE_PLAN, static fn ($i) => $i[3])),
        count($PRODUCTS),
        count($BROADCASTS),
    ));
    echo "\n-- DRY RUN: nothing written --\n";
    exit(0);
}

$madeInvoices = 0;
$madePayments = 0;
foreach ($INVOICE_PLAN as [$number, $dueIn, $amount, $paid]) {
    $invoice = $invoices->create([
        'number' => $number,
        'customer_name' => $CUSTOMER['name'],
        'customer_email' => $CUSTOMER['email'],
        'due_date' => $d($dueIn),
        'sent_at' => $dt($dueIn - 30),
        'amount' => number_format($amount, 2, '.', ''),
        'source' => MARKER,
    ]);
    $madeInvoices++;

    if ($paid) {
        // Settled a few days before the due date -- paid_on is what drives the
        // financial series, so it is set explicitly rather than left to now().
        $payments->create([
            'invoice_id' => $invoice['id'],
            'amount' => number_format($amount, 2, '.', ''),
            'method' => 'ACH',
            'reference' => 'ACH-' . substr($number, -6),
            'payer_email' => $CUSTOMER['email'],
            'paid_on' => $d($dueIn - 4),
            'paid_at' => $dt($dueIn - 4),
            'source' => MARKER,
        ]);
        $madePayments++;
    }
}
$say("invoices: $madeInvoices   payments: $madePayments");

$madeProducts = 0;
foreach ($PRODUCTS as [$sku, $name, $desc, $price, $qty, $uom, $status]) {
    if ($products->findBySku($sku) !== null) {
        continue;
    }
    $products->create([
        'sku' => $sku,
        'name' => $name,
        'description' => $desc,
        'price' => number_format($price, 2, '.', ''),
        'quantity' => $qty,
        'uom' => $uom,
        'status' => $status,
        'source' => MARKER,
    ]);
    $madeProducts++;
}
$say("products: $madeProducts");

// Broadcasts go to MySQL, NOT through BroadcastRepository, and that is not a
// style choice. The app is split-brained here: BroadcastRepository writes to
// BiseraDB, but BroadcastApiController -- the endpoint this app calls -- reads
// with DB::table('broadcasts') against MySQL. Seeding through the repository
// put rows somewhere nothing reads. Writing here matches the reader, so the
// demo data is actually visible; the underlying split is reported separately
// and is a product bug, not a seeding detail.
$madeBroadcasts = 0;
foreach ($BROADCASTS as [$title, $message, $daysAgo]) {
    $exists = DB::table('broadcasts')->where('title', $title)->exists();
    if ($exists) {
        continue;
    }
    DB::table('broadcasts')->insert([
        'title' => $title,
        'subject' => $title,
        // normalizeRow() reads message ?? body ?? content ?? text; the MySQL
        // column is `body`.
        'body' => $message,
        'status' => 'SENT',
        'sent_at' => $dt($daysAgo),
        'created_at' => $dt($daysAgo),
        'updated_at' => $dt($daysAgo),
    ]);
    $madeBroadcasts++;
}
$say("broadcasts: $madeBroadcasts (written to MySQL, where the API reads)");

echo "\n== done ==\n";
echo "Verify:\n";
echo "  curl -s -H 'Accept: application/json' -H \"Authorization: Bearer \$TOK\" \\\n";
echo "    https://3rivers-v.onshoretech.ai/api/financials/summary\n";
