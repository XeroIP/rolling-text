/// Truncates [text] from the beginning to fit within [maxChars] code points.
/// Returns the original text if it's already within the limit.
String truncateRollingText(String text, int maxChars) {
  final runes = text.runes.toList();
  if (runes.length <= maxChars) return text;
  return String.fromCharCodes(runes.sublist(runes.length - maxChars));
}
