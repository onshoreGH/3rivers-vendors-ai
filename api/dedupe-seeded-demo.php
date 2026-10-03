<?php
/**
 * Remove duplicate seeded invoices/payments.
 *
 *   sudo -u www-data php dedupe-seeded-demo.php --dry-run
 *   sudo -u www-data php dedupe-seeded-demo.php
 *
 * Caused by re-running seed-vendor-demo.php with --force to pick up a fix to
 * the broadcast path: --force skips the already-seeded guard for every
 * collection, not just the one that changed, so invoices and payments were
 * inserted a second time.
 *
 * Keeps the LOWEST id for each invoice number and each payment reference and
 * soft-deletes the rest. Only touches rows carrying the seeder's own marker,
 * so genuine records that happen to share a number are never removed.
 */

use App\Repositories\InvoiceRepository;
use App\Repositories\PaymentRepository;

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

const MARKER = 'seed:vendor-demo';

$dry = in_array('--dry-run', $argv, true);
$say = static fn (string $m) => print("   $m\n");

$invoices = app(InvoiceRepository::class);
$payments = app(PaymentRepository::class);

/**
 * @param array<int, array<string,mixed>> $rows
 * @return array<int, int> ids to delete
 */
$pickDuplicates = static function (array $rows, string $keyField): array {
    $seen = [];
    $drop = [];
    // ascending id, so the first occurrence seen is the one kept
    usort($rows, static fn ($a, $b) => (int) $a['id'] <=> (int) $b['id']);
    foreach ($rows as $r) {
        if (($r['source'] ?? null) !== MARKER) {
            continue;  // never touch anything this seeder did not create
        }
        $key = (string) ($r[$keyField] ?? '');
        if ($key === '') {
            continue;
        }
        if (isset($seen[$key])) {
            $drop[] = (int) $r['id'];
        } else {
            $seen[$key] = true;
        }
    }
    return $drop;
};

echo "== invoices ==\n";
$invoiceRows = array_map(
    static fn ($o) => (array) $o,
    $invoices->search('', 1000)->items(),
);
$dropInvoices = $pickDuplicates($invoiceRows, 'number');
$say(sprintf('%d rows, %d duplicates to remove', count($invoiceRows), count($dropInvoices)));
$say($dropInvoices === [] ? '(none)' : 'ids: ' . implode(', ', $dropInvoices));

echo "== payments ==\n";
$paymentRows = $payments->recent(1000);
$dropPayments = $pickDuplicates($paymentRows, 'reference');
$say(sprintf('%d rows, %d duplicates to remove', count($paymentRows), count($dropPayments)));
$say($dropPayments === [] ? '(none)' : 'ids: ' . implode(', ', $dropPayments));

if ($dry) {
    echo "\n-- DRY RUN: nothing written --\n";
    exit(0);
}

foreach ($dropInvoices as $id) {
    $invoices->softDelete($id);
}
foreach ($dropPayments as $id) {
    $payments->softDelete($id);
}

echo "\n== done: removed " . count($dropInvoices) . " invoices, " . count($dropPayments) . " payments ==\n";
