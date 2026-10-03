/// Small parsing helpers shared by the model `fromJson` factories. Kept
/// permissive: the mobile API is new and a missing/late field should
/// degrade to a sensible default, not crash a screen.
DateTime? parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString())?.toLocal();
}

DateTime parseDateOr(dynamic v, DateTime fallback) => parseDate(v) ?? fallback;

int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? fallback;
}

String asString(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

List<String> asStringList(dynamic v) => v is List
    ? v.map((e) => e.toString()).toList(growable: false)
    : const [];
