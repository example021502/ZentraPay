/// Renders a backend timestamp string in the canonical date/time format used
/// by the app's transaction history (`home_transactions.dart`):
/// `2026-10-05 • 15:28`.
///
/// The backend serialises timestamps as ISO-8601 strings (e.g.
/// `2026-10-05T15:28:50.542109`), so every consumer must pass the raw string
/// through here before displaying it.
///
/// * Blank/unparseable input yields `'undefined'` instead of guessing — we
///   never fabricate "now" for a financial record, because a silently wrong
///   date is worse than an obviously missing one.
/// * [DateTime.toLocal] guards against timestamps that do arrive with a `Z`
///   or offset suffix, which would otherwise render as UTC.
String formatDateTimeString(String? timestampStr) {
  final raw = timestampStr?.trim() ?? '';
  if (raw.isEmpty) return 'undefined';

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return 'undefined';

  final dateTime = parsed.toLocal();
  final dateOnly =
      "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  final timeOnly =
      "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

  return "$dateOnly • $timeOnly";
}
