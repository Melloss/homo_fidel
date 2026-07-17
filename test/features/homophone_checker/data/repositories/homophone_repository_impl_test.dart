import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/features/homophone_checker/data/datasources/family_local_data_source.dart';
import 'package:homofidel/features/homophone_checker/data/repositories/homophone_repository_impl.dart';

void main() {
  // The real data source, not a mock: the tables plus the arithmetic ARE the
  // engine, and the spec's worked examples are only meaningful against them.
  const repository = HomophoneRepositoryImpl(
    localDataSource: FamilyLocalDataSourceImpl(),
  );

  group('scan — known letters across all four families', () {
    test('S family, order 3 (spec worked example): ሳ → ሣ', () {
      final flags = repository.scan('ሳ');
      expect(flags, hasLength(1));
      final flag = flags.single;
      expect(flag.index, 0);
      expect(flag.character, 'ሳ');
      expect(flag.family.id, 'S');
      expect(flag.order, 3);
      expect(flag.siblings, ['ሣ']);
    });

    test('H family, order 3: ኃ → ሃ and ሓ', () {
      final flag = repository.scan('ኃ').single;
      expect(flag.family.id, 'H');
      expect(flag.order, 3);
      expect(flag.siblings, ['ሃ', 'ሓ']);
    });

    test('H family, order 5: ህ → ሕ and ኅ', () {
      final flag = repository.scan('ህ').single;
      expect(flag.order, 5);
      expect(flag.siblings, ['ሕ', 'ኅ']);
    });

    test("Ts' family, order 3: ጻ → ፃ", () {
      final flag = repository.scan('ጻ').single;
      expect(flag.family.id, 'TS');
      expect(flag.order, 3);
      expect(flag.siblings, ['ፃ']);
    });

    test("Ts' family, reverse direction, order 0: ፀ → ጸ", () {
      final flag = repository.scan('ፀ').single;
      expect(flag.order, 0);
      expect(flag.siblings, ['ጸ']);
    });

    test('A family, order 0: አ → ዐ', () {
      final flag = repository.scan('አ').single;
      expect(flag.family.id, 'A');
      expect(flag.order, 0);
      expect(flag.siblings, ['ዐ']);
    });

    test('A family, order 2: ዒ → ኢ', () {
      final flag = repository.scan('ዒ').single;
      expect(flag.order, 2);
      expect(flag.siblings, ['ኢ']);
    });

    test('one letter from each family in one string flags all four, in order',
        () {
      final flags = repository.scan('ሀሰጸአ');
      expect(flags.map((f) => f.family.id), ['H', 'S', 'TS', 'A']);
      expect(flags.map((f) => f.index), [0, 1, 2, 3]);
    });
  });

  group('scan — non-members produce zero flags', () {
    test('Latin, digits, punctuation', () {
      expect(repository.scan('Hello, world 123!'), isEmpty);
    });

    test('empty input is safe', () {
      expect(repository.scan(''), isEmpty);
    });

    test('Ge\'ez letters outside every family (e.g. መ, ለ, ፊ, ደ)', () {
      expect(repository.scan('መለፊደ'), isEmpty);
    });

    test('Ethiopic punctuation and digits', () {
      expect(repository.scan('። ፣ ፩ ፪'), isEmpty);
    });
  });

  group('scan — boundaries (base + 6 is the last member, base + 7 is not)', () {
    test('order 6 (o) letters ARE flagged', () {
      expect(repository.scan('ሆ').single.siblings, ['ሖ', 'ኆ']);
      expect(repository.scan('ጾ').single.siblings, ['ፆ']);
    });

    test('labiovelar variants at base + 7 are NOT flagged', () {
      // ሇ ሗ ሧ ሷ ኧ ጿ ፇ — real, different letters one past each family range.
      expect(repository.scan('ሇሗሧሷኧጿፇ'), isEmpty);
    });

    test('letters just below each base are NOT flagged', () {
      // ሯ (0x122F, below ሰ), ቿ (0x127F, below ኀ), ጷ (0x1337, below ጸ),
      // ኟ (0x129F, below አ), ዏ (0x12CF, below ዐ).
      expect(repository.scan('ሯቿጷኟዏ'), isEmpty);
    });
  });

  group('scan — indices', () {
    test('are positions in mixed Latin/Ge\'ez text', () {
      final flags = repository.scan('abc ሰ x ዐ');
      expect(flags.map((f) => f.index), [4, 8]);
      expect(flags.map((f) => f.character), ['ሰ', 'ዐ']);
    });

    test('are UTF-16 code-unit offsets: a surrogate pair counts as 2', () {
      // 😀 is U+1F600, two code units — ሰ sits at code-unit index 2.
      final flag = repository.scan('😀ሰ').single;
      expect(flag.index, 2);
      expect('😀ሰ'.substring(flag.index, flag.index + 1), 'ሰ');
    });

    test('a realistic sentence flags every choice point at its offset', () {
      const text = 'ሰላም ፀሐይ'; // "hello" + "sun"
      final flags = repository.scan(text);
      // ሰ (S), ፀ (TS), ሐ (H) — ላ, ም, ይ are not in any family.
      expect(flags.map((f) => f.character), ['ሰ', 'ፀ', 'ሐ']);
      for (final flag in flags) {
        expect(text[flag.index], flag.character);
      }
    });
  });
}
