<?php

namespace App\Http\Controllers\Api;

use App\Repositories\ProductRepository;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;

/**
 * Product catalogue for the vendor mobile app. Replaces a stub that returned
 * a hardcoded empty array.
 *
 * Note ProductRepository::search() takes ($q, $status, $perPage) -- the status
 * argument is REQUIRED and is not optional as the Invoice and Vendor
 * repositories' search() signatures would suggest. Passing '' means "any
 * status"; omitting it is a TypeError, not a default.
 */
class ProductController extends Controller
{
    public function __construct(private readonly ProductRepository $products)
    {
    }

    public function index(Request $request)
    {
        $perPage = max(1, min((int) $request->query('per_page', 25), 100));

        $page = $this->products->search(
            (string) $request->query('q', ''),
            (string) $request->query('status', ''),
            $perPage,
        );

        return response()->json([
            'status' => 'ok',
            // paginate() hands back stdClass for the Blade views; flatten.
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
        $product = $this->products->find((int) $id);

        if ($product === null) {
            return response()->json(['status' => 'error', 'message' => 'Product not found.'], 404);
        }

        return response()->json(['status' => 'ok', 'data' => $product]);
    }

    public function store(Request $request)
    {
        return response()->json([
            'status' => 'error',
            'message' => 'Creating products is not supported from the mobile app.',
        ], 405);
    }

    public function update(Request $request, $id)
    {
        return response()->json([
            'status' => 'error',
            'message' => 'Editing products is not supported from the mobile app.',
        ], 405);
    }

    public function destroy($id)
    {
        return response()->json([
            'status' => 'error',
            'message' => 'Deleting products is not supported from the mobile app.',
        ], 405);
    }
}
