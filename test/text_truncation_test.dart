import 'package:flutter_test/flutter_test.dart';
import 'package:rolling_text/utils/text_truncation.dart';

void main() {
  group('truncateRollingText', () {
    test('returns text unchanged when shorter than limit', () {
      expect(truncateRollingText('hello', 10), 'hello');
    });

    test('returns text unchanged when exactly at limit', () {
      expect(truncateRollingText('hello', 5), 'hello');
    });

    test('removes oldest characters when exceeding limit', () {
      expect(truncateRollingText('hello world', 5), 'world');
    });

    test('returns empty string for empty input', () {
      expect(truncateRollingText('', 10), '');
    });

    test('works with single-char limit', () {
      expect(truncateRollingText('abc', 1), 'c');
    });

    test('handles single character input at limit', () {
      expect(truncateRollingText('a', 1), 'a');
    });

    test('handles multi-byte unicode characters', () {
      // Each CJK character is one code point
      expect(truncateRollingText('你好世界', 2), '世界');
    });

    test('handles emoji as code points', () {
      // Simple emoji: each is one code point
      expect(truncateRollingText('😀😎🎉', 2), '😎🎉');
    });

    test('handles ZWJ emoji sequences as multiple code points', () {
      // Family emoji 👨‍👩‍👧‍👦 is 7 code points (4 emoji + 3 ZWJ)
      const family = '👨\u200D👩\u200D👧\u200D👦';
      final runeCount = family.runes.length;
      expect(runeCount, 7);
      // Truncating to 7 should keep it intact
      expect(truncateRollingText(family, 7), family);
    });

    test('handles mixed ASCII and multi-byte characters', () {
      expect(truncateRollingText('abc你好', 3), 'c你好');
    });

    test('handles accented characters', () {
      // é as a single precomposed code point
      expect(truncateRollingText('café', 3), 'afé');
    });
  });
}
