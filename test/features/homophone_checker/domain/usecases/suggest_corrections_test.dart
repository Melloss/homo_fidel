import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/features/homophone_checker/data/datasources/family_local_data_source.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/suggest_corrections.dart';

import '../../helpers/fake_word_frequency_repository.dart';

void main() {
  final families = const FamilyLocalDataSourceImpl().families;

  SuggestCorrections build(FakeWordFrequencyRepository repository) =>
      SuggestCorrections(families: families, repository: repository);

  group('the dominance rule', () {
    test('suggests the common spelling for a rare typed variant', () {
      final suggest = build(
        const FakeWordFrequencyRepository({'ሰላም': 5490, 'ሠላም': 50}),
      );
      final s = suggest(const SuggestCorrectionsParams('ሠላም')).single;
      expect(s.typed, 'ሠላም');
      expect(s.suggested, 'ሰላም');
      expect(s.typedCount, 50);
      expect(s.suggestedCount, 5490);
      expect(s.index, 0);
    });

    test('stays silent when the typed spelling dominates', () {
      final suggest = build(
        const FakeWordFrequencyRepository({'ሰላም': 5490, 'ሠላም': 50}),
      );
      expect(suggest(const SuggestCorrectionsParams('ሰላም')), isEmpty);
    });

    test('stays silent when the evidence is not lopsided enough', () {
      // 3:1 is nowhere near the 20x dominance bar.
      final suggest = build(
        const FakeWordFrequencyRepository({'ሰላም': 300, 'ሠላም': 100}),
      );
      expect(suggest(const SuggestCorrectionsParams('ሠላም')), isEmpty);
    });

    test('a typed word absent from the corpus still needs an attested variant',
        () {
      final suggest = build(
        const FakeWordFrequencyRepository({'ሰላም': 5490}),
      );
      // ሠላም absent -> suggest ሰላም; ሧላም is not a family variant of anything.
      final s = suggest(const SuggestCorrectionsParams('ሠላም')).single;
      expect(s.typedCount, 0);
      expect(s.suggested, 'ሰላም');
    });

    test('suggests nothing when every variant is rare or absent', () {
      final suggest = build(
        const FakeWordFrequencyRepository({'ሰላም': 4}),
      );
      expect(suggest(const SuggestCorrectionsParams('ሠላም')), isEmpty);
    });
  });

  group('multi-letter words', () {
    test('fixes the one wrong letter and leaves the right ones alone', () {
      // ፀሐይ -> ፀሀይ changes only the middle letter.
      final suggest = build(
        const FakeWordFrequencyRepository({'ፀሀይ': 363, 'ፀሐይ': 4}),
      );
      final s = suggest(const SuggestCorrectionsParams('ፀሐይ')).single;
      expect(s.suggested, 'ፀሀይ');
      expect(s.changedIndices, [1]);
      expect(s.characterAt(1), 'ሀ');
    });

    test('picks the best variant among several attested ones', () {
      final suggest = build(
        const FakeWordFrequencyRepository({'ፀሀይ': 363, 'ጸሀይ': 40, 'ፀሐይ': 4}),
      );
      final s = suggest(const SuggestCorrectionsParams('ፀሐይ')).single;
      expect(s.suggested, 'ፀሀይ');
    });
  });

  group('positions and context', () {
    test('indices are code-unit offsets into the full text', () {
      final suggest = build(
        const FakeWordFrequencyRepository({'ሰላም': 5490, 'ሠላም': 50}),
      );
      final all = suggest(const SuggestCorrectionsParams('እንደምን ሠላም ነህ'));
      final s = all.single;
      expect(s.index, 6);
      expect(s.changedIndices, [6]);
    });

    test('each word is judged independently', () {
      final suggest = build(
        const FakeWordFrequencyRepository(
          {'ሰላም': 5490, 'ሠላም': 50, 'ሀገር': 5345, 'ሐገር': 2},
        ),
      );
      final all = suggest(const SuggestCorrectionsParams('ሠላም ሐገር'));
      expect(all.map((s) => s.suggested), ['ሰላም', 'ሀገር']);
    });
  });

  group('degradation and guards', () {
    test('returns nothing when the frequency list is unavailable', () {
      final suggest = build(const FakeWordFrequencyRepository.unavailable());
      expect(suggest(const SuggestCorrectionsParams('ሠላም')), isEmpty);
    });

    test('words with no family letter are never looked up', () {
      final suggest = build(const FakeWordFrequencyRepository({'መልካም': 999}));
      expect(suggest(const SuggestCorrectionsParams('መልካም ቀን')), isEmpty);
    });

    test('non-Ge\'ez and empty input are safe', () {
      final suggest = build(const FakeWordFrequencyRepository({}));
      expect(suggest(const SuggestCorrectionsParams('')), isEmpty);
      expect(suggest(const SuggestCorrectionsParams('hello 123')), isEmpty);
    });

    test('a word with an exploding variant space is skipped, not enumerated',
        () {
      // 8 H-family letters -> 3^8 = 6561 variants > maxVariants.
      final word = 'ሀ' * 8;
      final suggest = build(FakeWordFrequencyRepository({'ሐ' * 8: 1000}));
      expect(suggest(SuggestCorrectionsParams(word)), isEmpty);
    });
  });
}
