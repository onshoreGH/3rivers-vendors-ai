import 'package:flutter_test/flutter_test.dart';
import 'package:onshore_3rivers_vendors/core/models/vendor_models.dart';

void main() {
  test('asMoney parses the decimal STRINGS the Laravel API returns', () {
    // MySQL decimal columns serialise as strings through PDO; parsing them as
    // num would silently yield 0 for every amount on every screen.
    expect(asMoney('4820.00'), 4820.00);
    expect(asMoney('0.00'), 0);
    expect(asMoney(1295.75), 1295.75);
    expect(asMoney(null), 0);
    expect(asMoney('not a number'), 0);
  });

  test('Invoice.isPastDue compares the due date against today', () {
    final past = Invoice.fromJson({
      'id': 1,
      'number': 'INV-2026-0203',
      'due_date': '2020-01-01',
      'amount': '2890.25',
    });
    expect(past.isPastDue, isTrue);
    expect(past.amount, 2890.25);

    final future = Invoice.fromJson({
      'id': 2,
      'number': 'INV-2026-0224',
      'due_date': '2099-01-01',
      'amount': '9320.50',
    });
    expect(future.isPastDue, isFalse);
  });

  test('Invoice with no due date is not treated as past due', () {
    final none = Invoice.fromJson({'id': 3, 'number': 'INV-X'});
    expect(none.isPastDue, isFalse);
  });

  test('Payment falls back to created_at when paid_on is null', () {
    // Live rows have paid_on and paid_at both null; the server applies the
    // same fallback for its totals.
    final p = Payment.fromJson({
      'id': 1,
      'amount': '99.00',
      'paid_on': null,
      'created_at': '2026-04-04T11:31:55',
    });
    expect(p.paidOn, '2026-04-04T11:31:55');
  });

  test('FinancialSummary surfaces expenses_available rather than defaulting', () {
    final s = FinancialSummary.fromJson({
      'revenue': 24770.25,
      'payments_count': 7,
      'invoices_count': 10,
      'expenses_available': false,
      'currency': 'USD',
    });
    expect(s.expensesAvailable, isFalse);
    expect(s.revenue, 24770.25);
  });

  test('Product.isActive is case-insensitive on the status string', () {
    expect(Product.fromJson({'status': 'ACTIVE'}).isActive, isTrue);
    expect(Product.fromJson({'status': 'active'}).isActive, isTrue);
    expect(Product.fromJson({'status': 'INACTIVE'}).isActive, isFalse);
  });
}
