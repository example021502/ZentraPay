String formatDateTimeString(String timestampStr) {
  // Split the string by the space between date and time
  List<String> parts = timestampStr.split('T');

  if (parts.length >= 2) {
    String datePart = parts[0]; // "2026-08-16"
    String timePart = parts[1].split(
      '.',
    )[0]; // Removes microseconds -> "13:58:16"
    List<String> timeParts = timePart.split(":");
    String hours = timeParts[0];
    String minutes = timeParts[1];

    return "$datePart • $hours:$minutes";
  }

  return timestampStr; // Fallback if format is unexpected
}
