<?php

namespace App\Http\Controllers\Api;

use App\Repositories\InvoiceRepository;
use App\Repositories\PaymentRepository;
use Illuminate\Routing\Controller;

/**
 * Financial summary for the vendor mobile app's home screen.
 *
 * Replaces a stub that returned revenue/expenses/profit all hardcoded to 0 --
 * indistinguishable from a real but empty account, which is precisely the kind
 * of screen that draws an App Review 2.1 "incomplete features" rejection.
 *
 * EXPENSES ARE NOT REPORTED. There is no ExpenseRepository and no expenses
 * collection anywhere in this application: expenses exist only as a route and
 * a stub controller. Returning 0 would assert "no expenses" when the truth is
 * "no expense data source", so the keys are omitted and `expenses_available`
 * says so explicitly. Profit is omitted for the same reason -- it cannot be
 * computed without the expense side, and a profit equal to revenue would be
 * actively misleading on a financial screen.
 */
class FinancialController extends Controller
{
    public function __construct(
        private readonly PaymentRepository $payments,
        private readonly InvoiceRepository $invoices,
    ) {
    }

    public function summary()
    {
        $payments = $this->payments->recent(5000);

        $revenue = 0.0;
        $latest = null;
        foreach ($payments as $p) {
            $revenue += (float) ($p['amount'] ?? 0);
            $paidOn = $p['paid_on'] ?? null;
            if ($paidOn !== null && ($latest === null || $paidOn > $latest)) {
                $latest = $paidOn;
            }
        }

        // search('') is the repository's "everything" path; total() is the
        // unpaginated count.
        $invoiceCount = $this->invoices->search('', 1)->total();

        return response()->json([
            'status' => 'ok',
            'data' => [
                'revenue' => round($revenue, 2),
                'payments_count' => count($payments),
                'last_payment_on' => $latest,
                'invoices_count' => $invoiceCount,
                'expenses_available' => false,
                'currency' => 'USD',
            ],
        ]);
    }

    public function overview()
    {
        $payments = $this->payments->recent(5000);

        // Group by calendar month of paid_on, newest first. Rows with no
        // paid_on are counted separately rather than silently dropped or
        // bucketed into whatever month today happens to be.
        $byMonth = [];
        $undated = 0;
        foreach ($payments as $p) {
            $paidOn = $p['paid_on'] ?? null;
            if (!is_string($paidOn) || strlen($paidOn) < 7) {
                $undated++;
                continue;
            }
            $month = substr($paidOn, 0, 7);
            $byMonth[$month] ??= ['month' => $month, 'total' => 0.0, 'count' => 0];
            $byMonth[$month]['total'] += (float) ($p['amount'] ?? 0);
            $byMonth[$month]['count']++;
        }

        krsort($byMonth);
        $series = array_values(array_map(
            static fn (array $m) => ['month' => $m['month'], 'total' => round($m['total'], 2), 'count' => $m['count']],
            $byMonth,
        ));

        return response()->json([
            'status' => 'ok',
            'data' => [
                'by_month' => array_slice($series, 0, 12),
                'undated_payments' => $undated,
                'expenses_available' => false,
                'currency' => 'USD',
            ],
        ]);
    }
}
