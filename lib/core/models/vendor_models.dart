import 'json.dart';

/// Money arrives from the Laravel API as a STRING ("4820.00"), not a number --
/// MySQL decimal columns serialise that way through PDO. asInt/num parsing
/// would silently yield 0 for every amount, so it is parsed explicitly here
/// and nowhere else.
double asMoney(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v == null) return fallback;
  return double.tryParse(v.toString()) ?? fallback;
}

class Invoice {
  final String id;
  final String number;
  final String customerName;
  final String customerEmail;
  final String? dueDate; // YYYY-MM-DD
  final DateTime? sentAt;
  final double amount;

  const Invoice({
    required this.id,
    required this.number,
    required this.customerName,
    required this.customerEmail,
    required this.dueDate,
    required this.sentAt,
    required this.amount,
  });

  /// The API carries no paid/unpaid flag -- settlement lives in the payments
  /// collection, which this screen does not join. "Overdue" here means only
  /// that the due date has passed; the Invoices list says "Due <date>" rather
  /// than claiming a payment status it cannot actually know.
  bool get isPastDue {
    final d = parseDate(dueDate);
    return d != null && d.isBefore(DateTime.now());
  }

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: asString(json['id']),
        number: asString(json['number']),
        customerName: asString(json['customer_name']),
        customerEmail: asString(json['customer_email']),
        dueDate: json['due_date']?.toString(),
        sentAt: parseDate(json['sent_at']),
        amount: asMoney(json['amount']),
      );
}

class Payment {
  final String id;
  final String invoiceId;
  final double amount;
  final String method;
  final String reference;
  final String? paidOn;

  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.reference,
    required this.paidOn,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: asString(json['id']),
        invoiceId: asString(json['invoice_id']),
        amount: asMoney(json['amount']),
        method: asString(json['method']),
        reference: asString(json['reference']),
        // paid_on is frequently null on older rows; the server falls back to
        // created_at for its own totals, so absence here is normal, not a bug.
        paidOn: json['paid_on']?.toString() ?? json['created_at']?.toString(),
      );
}

class Product {
  final String id;
  final String sku;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String uom;
  final String status;

  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.uom,
    required this.status,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: asString(json['id']),
        sku: asString(json['sku']),
        name: asString(json['name']),
        description: asString(json['description']),
        price: asMoney(json['price']),
        quantity: asInt(json['quantity']),
        uom: asString(json['uom']),
        status: asString(json['status']),
      );
}

class Broadcast {
  final String id;
  final String title;
  final String message;
  final DateTime? createdAt;
  final bool isRead;

  const Broadcast({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory Broadcast.fromJson(Map<String, dynamic> json) => Broadcast(
        id: asString(json['id']),
        title: asString(json['title']),
        message: asString(json['message']),
        createdAt: parseDate(json['created_at']),
        isRead: json['is_read'] == true,
      );
}

/// GET /api/financials/summary
class FinancialSummary {
  final double revenue;
  final int paymentsCount;
  final String? lastPaymentOn;
  final int invoicesCount;

  /// False whenever the server has no expense data source at all -- which is
  /// currently always. The home screen must say so rather than render a zero,
  /// because "no expenses" and "no expense data" look identical otherwise.
  final bool expensesAvailable;
  final String currency;

  const FinancialSummary({
    required this.revenue,
    required this.paymentsCount,
    required this.lastPaymentOn,
    required this.invoicesCount,
    required this.expensesAvailable,
    required this.currency,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) =>
      FinancialSummary(
        revenue: asMoney(json['revenue']),
        paymentsCount: asInt(json['payments_count']),
        lastPaymentOn: json['last_payment_on']?.toString(),
        invoicesCount: asInt(json['invoices_count']),
        expensesAvailable: json['expenses_available'] == true,
        currency: asString(json['currency'], 'USD'),
      );
}

class MonthTotal {
  final String month; // YYYY-MM
  final double total;
  final int count;

  const MonthTotal({
    required this.month,
    required this.total,
    required this.count,
  });

  factory MonthTotal.fromJson(Map<String, dynamic> json) => MonthTotal(
        month: asString(json['month']),
        total: asMoney(json['total']),
        count: asInt(json['count']),
      );
}
