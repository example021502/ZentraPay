import 'dart:math';

String generateTxnRef({String prefix = 'ZP'}) {
  final now = DateTime.now().toUtc();

  // Format timestamp: YYYYMMDDHHMMSS (e.g., 20260812114204)
  final timestamp =
      "${now.year}"
      "${now.month.toString().padLeft(2, '0')}"
      "${now.day.toString().padLeft(2, '0')}"
      "${now.hour.toString().padLeft(2, '0')}"
      "${now.minute.toString().padLeft(2, '0')}"
      "${now.second.toString().padLeft(2, '0')}";

  // Generate a 5-character random alphanumeric suffix to prevent collisions
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  final randomSuffix = String.fromCharCodes(
    Iterable.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
  );

  return "${prefix}_${timestamp}_$randomSuffix";
}
