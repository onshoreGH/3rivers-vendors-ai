<?php

namespace App\Http\Controllers\Api;

use App\Repositories\PaymentRepository;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;

/**
 * Payments for the vendor mobile app. Replaces a stub that returned a
 * hardcoded empty array.
 *
 * PaymentRepository exposes recent(int $limit) and nothing else, so paging is
 * done here over that result rather than pushed into the repository -- the web
 * side has no paged payments view to share with, and widening the repository
 * for one caller would be a change to code the browser portal depends on.
 */
class PaymentController extends Controller
{
    /** Matches the repository's own default ceiling. */
    private const MAX_FETCH = 200;

    public function __construct(private readonly PaymentRepository $payments)
    {
    }

    public function index(Request $request)
    {
        $perPage = max(1, min((int) $request->query('per_page', 25), 100));
        $page = max(1, (int) $request->query('page', 1));

        $all = $this->payments->recent(self::MAX_FETCH);
        $total = count($all);
        $slice = array_slice($all, ($page - 1) * $perPage, $perPage);

        return response()->json([
            'status' => 'ok',
            'data' => array_values($slice),
            'meta' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'last_page' => max(1, (int) ceil($total / $perPage)),
                // Surfaced rather than hidden: beyond this the list is capped
                // by the repository, not genuinely exhausted.
                'capped_at' => self::MAX_FETCH,
            ],
        ]);
    }

    public function show($id)
    {
        $payment = $this->payments->find((int) $id);

        if ($payment === null) {
            return response()->json(['status' => 'error', 'message' => 'Payment not found.'], 404);
        }

        return response()->json(['status' => 'ok', 'data' => $payment]);
    }

    public function store(Request $request)
    {
        return response()->json([
            'status' => 'error',
            'message' => 'Recording payments is not supported from the mobile app.',
        ], 405);
    }

    public function update(Request $request, $id)
    {
        return response()->json([
            'status' => 'error',
            'message' => 'Editing payments is not supported from the mobile app.',
        ], 405);
    }

    public function destroy($id)
    {
        return response()->json([
            'status' => 'error',
            'message' => 'Deleting payments is not supported from the mobile app.',
        ], 405);
    }
}
