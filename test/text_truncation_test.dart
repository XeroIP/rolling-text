import 'package:characters/characters.dart';
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

    test('handles ZWJ emoji sequences as a single grapheme cluster', () {
      // Family emoji is 7 code points (4 emoji + 3 ZWJ) but one extended
      // grapheme cluster, so it must never be split at the boundary.
      const family = '👨‍👩‍👧‍👦';
      expect(family.characters.length, 1);
      // Truncating to 1 should keep the whole cluster intact.
      expect(truncateRollingText(family, 1), family);
      // A limit of 0 must drop the whole cluster, not a fragment of it.
      expect(truncateRollingText(family, 0), '');
    });

    test('does not split a family emoji when truncating around the boundary', () {
      const family = '👨‍👩‍👧‍👦';
      final text = 'ab$family';
      // 3 graphemes total: 'a', 'b', family. Limit of 2 must drop 'a' only,
      // never break the ZWJ sequence apart.
      expect(truncateRollingText(text, 2), 'b$family');
    });

    test('handles mixed ASCII and multi-byte characters', () {
      expect(truncateRollingText('abc你好', 3), 'c你好');
    });

    test('handles precomposed accented characters', () {
      // é as a single precomposed code point
      expect(truncateRollingText('café', 3), 'afé');
    });

    test('does not split a combining accent from its base letter', () {
      // e + combining acute accent (U+0301) is two code points but one
      // grapheme cluster; truncation must keep them together.
      const combiningE = 'é';
      final text = 'caf$combiningE';
      expect(combiningE.characters.length, 1);
      expect(truncateRollingText(text, 1), combiningE);
      expect(truncateRollingText(text, 2), 'f$combiningE');
    });

    test('does not split a regional indicator flag sequence', () {
      // Flag emoji (JP flag) is a pair of regional indicator code points
      // but a single grapheme cluster.
      const flag = '🇯🇵';
      final text = 'hi$flag';
      expect(flag.characters.length, 1);
      expect(truncateRollingText(text, 1), flag);
      expect(truncateRollingText(text, 2), 'i$flag');
    });

    test('does not split an emoji skin-tone modifier sequence', () {
      // A base emoji plus a Fitzpatrick skin-tone modifier is two code
      // points but a single grapheme cluster.
      const wave = '👋🏽';
      final text = 'hi$wave';
      expect(wave.characters.length, 1);
      expect(truncateRollingText(text, 1), wave);
      expect(truncateRollingText(text, 2), 'i$wave');
    });
  });
}
