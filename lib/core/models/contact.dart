import 'json.dart';

/// A supplier or vendor in the 3Rivers directory.
class Contact {
  final String id;
  final String name;
  final String? email;
  final String contactType; // supplier | vendor
  final DateTime? createdAt;

  const Contact({
    required this.id,
    required this.name,
    required this.email,
    required this.contactType,
    required this.createdAt,
  });

  bool get isSupplier => contactType == 'supplier';
  String get typeLabel => isSupplier ? 'Supplier' : 'Vendor';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0]).join().toUpperCase();
    return letters.isEmpty ? '?' : letters;
  }

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: asString(json['id']),
        name: asString(json['name'], '(unnamed)'),
        email: (json['email'] as String?)?.trim().isEmpty ?? true
            ? null
            : asString(json['email']),
        contactType: asString(json['contact_type'], 'supplier'),
        createdAt: parseDate(json['created_at']),
      );
}

/// A video check-in session with a contact.
class CheckInSession {
  final String id;
  final String status;
  final String initiatedBy;
  final DateTime? createdAt;

  const CheckInSession({
    required this.id,
    required this.status,
    required this.initiatedBy,
    required this.createdAt,
  });

  factory CheckInSession.fromJson(Map<String, dynamic> json) => CheckInSession(
        id: asString(json['id']),
        status: asString(json['status'], 'pending'),
        initiatedBy: asString(json['initiated_by']),
        createdAt: parseDate(json['created_at']),
      );
}

/// Result of POST /api/v1/directory/{type}/{id}/check-in.
class CheckInInvite {
  final String sessionId;
  final String hostUrl;
  final String guestUrl;

  const CheckInInvite({
    required this.sessionId,
    required this.hostUrl,
    required this.guestUrl,
  });

  factory CheckInInvite.fromJson(Map<String, dynamic> json) => CheckInInvite(
        sessionId: asString(json['session_id']),
        hostUrl: asString(json['host_url']),
        guestUrl: asString(json['guest_url']),
      );
}
