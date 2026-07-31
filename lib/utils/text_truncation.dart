import 'package:characters/characters.dart';

/// Truncates [text] from the beginning to fit within [maxChars] extended
/// grapheme clusters. Returns the original text if it's already within the limit.
String truncateRollingText(String text, int maxChars) {
  final chars = text.characters;
  if (chars.length <= maxChars) return text;
  return chars.takeLast(maxChars).toString();
}
