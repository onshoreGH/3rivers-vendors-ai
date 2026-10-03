<?php

namespace App\Http\Controllers\Api;

use App\Repositories\InvoiceRepository;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;

/**
 * Invoices for the vendor mobile app.
 *
 * Replaces a 15-line stub whose index() returned a hardcoded empty array, so
 * the endpoint answered 200 with no data and looked like an empty account
 * rather than an unimplemented one.
 *
 * Records are passed through as stored rather than mapped onto a fixed DTO:
 * invoices here carry no local total/amount column (the admin side only lists
 * and sends them), so naming an expected shape would invent fields. The app
 * renders what is present and tolerates absence.
 */
class InvoiceController extends Controller
{
    public function __construct(private readonly InvoiceRepository $invoices)
    {
    }

    public function index(Request $request)
    {
        $perPage = (int) $request->query('per_page', 25);
        $perPage = max(1, min($perPage, 100));

        // search('') is the repository's "everything, newest first" path --
        // it sorts by record.id desc before filtering.
        $page = $this->invoices->search((string) $request->query('q', ''), $perPage);

        return response()->json([
            'status' => 'ok',
            // paginate() casts rows to stdClass for the Blade views; cast back
            // so the JSON is objects of plain fields rather than nested gunk.
            'data' => array_map(static fn ($row) => (array) $row, $page->items()),
            'meta' => [
                'page' => $page->currentPage(),
                'per_page' => $page->perPage(),
                'total' => $page->total(),
                'last_page' => $page->lastPage(),
            ],
        ]);
    }

    public function show($id)
    {
        $invoice = $this->invoices->find((int) $id);

        if ($invoice === null) {
            return response()->json(['status' => 'error', 'message' => 'Invoice not found.'], 404);
        }

        return response()->json(['status' => 'ok', 'data' => $invoice]);
    }

    public function store(Request $request)
    {
        return response()->json([
            'status' => 'error',
            'message' => 'Creating invoices is not supported from the mobile app.',
        ], 405);
    }

    public function update(Request $request, $id)
    {
        return response()->json([
            'status' => 'error',
            'message' => 'Editing invoices is not supported from the mobile app.',
        ], 405);
    }

    public function destroy($id)
    {
        return response()->json([
            'status' => 'error',
            'message' => 'Deleting invoices is not supported from the mobile app.',
        ], 405);
    }
}
