import 'json.dart';

class InboxMessage {
  final String id;
  final String kind; // email-out | email-in | sms-out | sms-in
  final String from;
  final String to;
  final String subject;
  final String body;
  final DateTime? createdAt;

  const InboxMessage({
    required this.id,
    required this.kind,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.createdAt,
  });

  bool get isInbound => kind.endsWith('-in');
  bool get isSms => kind.startsWith('sms');
  String get channelLabel => isSms ? 'SMS' : 'Email';
  String get directionLabel => isInbound ? 'Received' : 'Sent';

  factory InboxMessage.fromJson(Map<String, dynamic> json) => InboxMessage(
        id: asString(json['id']),
        kind: asString(json['kind'], 'email-out'),
        from: asString(json['from']),
        to: asString(json['to']),
        subject: asString(json['subject']),
        body: asString(json['body']),
        createdAt: parseDate(json['created_at']),
      );
}
