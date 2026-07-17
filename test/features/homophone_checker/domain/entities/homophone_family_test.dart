import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/features/homophone_checker/domain/entities/homophone_family.dart';

void main() {
  const h = HomophoneFamily(id: 'H', sound: '/h/', bases: [0x1200, 0x1210, 0x1280]);
  const s = HomophoneFamily(id: 'S', sound: '/s/', bases: [0x1230, 0x1220]);

  group('baseOf / contains', () {
    test('first order (ä) of every base is in the family', () {
      expect(h.baseOf(0x1200), 0x1200); // ሀ
      expect(h.baseOf(0x1210), 0x1210); // ሐ
      expect(h.baseOf(0x1280), 0x1280); // ኀ
    });

    test('last order (o, base + 6) is still in the family', () {
      expect(h.contains(0x1206), isTrue); // ሆ
      expect(s.contains(0x1236), isTrue); // ሶ
    });

    test('base + 7 — the labiovelar variant — is NOT in the family', () {
      expect(h.contains(0x1207), isFalse); // ሇ HOA
      expect(h.contains(0x1217), isFalse); // ሗ HHWA
      expect(s.contains(0x1237), isFalse); // ሷ SWA
      expect(s.contains(0x1227), isFalse); // ሧ SZWA
    });

    test('code point just below a base is NOT in the family', () {
      expect(s.contains(0x122F), isFalse); // ሯ, just below ሰ 0x1230
      expect(h.contains(0x11FF), isFalse); // below the Ethiopic block
    });
  });

  group('orderOf', () {
    test('is the offset from the base', () {
      expect(s.orderOf(0x1233), 3); // ሳ
      expect(h.orderOf(0x1283), 3); // ኃ
      expect(h.orderOf(0x1200), 0); // ሀ
      expect(h.orderOf(0x1206), 6); // ሆ
    });

    test('is null outside the family', () {
      expect(s.orderOf(0x1200), isNull);
      expect(s.orderOf(0x1237), isNull);
    });
  });

  group('siblingsOf', () {
    test('keeps the vowel order and changes the base (spec worked example)', () {
      expect(s.siblingsOf(0x1233), [0x1223]); // ሳ → ሣ
    });

    test('a three-base family yields two siblings', () {
      expect(h.siblingsOf(0x1283), [0x1203, 0x1213]); // ኃ → ሃ, ሓ
    });

    test('is empty outside the family', () {
      expect(s.siblingsOf(0x0041), isEmpty); // 'A'
      expect(s.siblingsOf(0x1237), isEmpty); // ሷ
    });
  });
}
