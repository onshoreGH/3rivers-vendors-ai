import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _time = DateFormat.jm();
final _dayMonth = DateFormat.MMMd();
final _dayMonthYear = DateFormat.yMMMd();
final _full = DateFormat.yMMMMd();

/// "3:04 PM" today, "Mar 12" this year, "Mar 12, 2025" otherwise.
String relativeDate(DateTime dt) {
  final now = DateTime.now();
  final d = DateTime(dt.year, dt.month, dt.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return _time.format(dt);
  if (diff == 1) return 'Yesterday';
  if (dt.year == now.year) return _dayMonth.format(dt);
  return _dayMonthYear.format(dt);
}

String fullDate(DateTime dt) => _full.format(dt);
String timeOfDay(DateTime dt) => _time.format(dt);

/// Render a `YYYY-MM-DD` string (or ISO datetime) as "Mar 12, 2026".
/// Falls back to the raw string when it can't be parsed, "—" when empty.
String shortDate(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  return d == null ? iso : _dayMonthYear.format(d);
}

/// Background tint for a status chip, keyed loosely by the status word.
Color statusTint(BuildContext context, String status) {
  final s = status.toLowerCase();
  final scheme = Theme.of(context).colorScheme;
  if (s.contains('complete') || s.contains('delivered') || s.contains('done')) {
    return scheme.primaryContainer;
  }
  if (s.contains('exception') ||
      s.contains('cancel') ||
      s.contains('overdue') ||
      s.contains('late')) {
    return scheme.errorContainer;
  }
  if (s.contains('transit') || s.contains('progress') || s.contains('shipped')) {
    return scheme.secondaryContainer;
  }
  return scheme.surfaceContainerHighest;
}

String titleCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "InProgress" -> "In Progress", "InTransit" -> "In Transit", leaves
/// already-spaced or single-word values alone.
String prettyStatus(String s) {
  final spaced = s.replaceAllMapped(
      RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ');
  return titleCase(spaced.trim());
}
