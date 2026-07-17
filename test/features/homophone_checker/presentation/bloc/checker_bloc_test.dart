import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/features/homophone_checker/data/datasources/family_local_data_source.dart';
import 'package:homofidel/features/homophone_checker/data/repositories/homophone_repository_impl.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/scan_text.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/suggest_corrections.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/swap_letter.dart';
import 'package:homofidel/features/homophone_checker/presentation/bloc/checker_bloc.dart';

import '../../helpers/fake_word_frequency_repository.dart';

void main() {
  // Real use cases over the real tables: the engine is deterministic and
  // fast, so mocking it would only test the mock. Only the Mode B frequency
  // list is faked, so tests control the corpus.
  const repository = HomophoneRepositoryImpl(
    localDataSource: FamilyLocalDataSourceImpl(),
  );
  const scanText = ScanText(repository);
  const swapLetter = SwapLetter();

  CheckerBloc buildBloc({Map<String, int>? corpus}) => CheckerBloc(
        scanText: scanText,
        swapLetter: swapLetter,
        suggestCorrections: SuggestCorrections(
          families: const FamilyLocalDataSourceImpl().families,
          repository: corpus == null
              ? const FakeWordFrequencyRepository.unavailable()
              : FakeWordFrequencyRepository(corpus),
        ),
      );

  test('starts in edit mode', () {
    expect(buildBloc().state, const CheckerEditing());
  });

  blocTest<CheckerBloc, CheckerState>(
    'Check scans the text and enters checked mode with its flags',
    build: buildBloc,
    act: (bloc) => bloc.add(const TextChecked('ሰላም')),
    verify: (bloc) {
      final state = bloc.state as CheckerResult;
      expect(state.text, 'ሰላም');
      expect(state.flags.single.character, 'ሰ');
      expect(state.flags.single.siblings, ['ሠ']);
    },
  );

  blocTest<CheckerBloc, CheckerState>(
    'checking text with no choice points yields an empty flag list',
    build: buildBloc,
    act: (bloc) => bloc.add(const TextChecked('hello ለም')),
    verify: (bloc) {
      expect((bloc.state as CheckerResult).flags, isEmpty);
    },
  );

  blocTest<CheckerBloc, CheckerState>(
    'choosing a sibling swaps the letter and re-scans',
    build: buildBloc,
    act: (bloc) {
      bloc.add(const TextChecked('ሰላም'));
      bloc.add(SiblingSwapped(
        letter: repository.scan('ሰላም').single,
        sibling: 'ሠ',
      ));
    },
    verify: (bloc) {
      final state = bloc.state as CheckerResult;
      expect(state.text, 'ሠላም');
      // Still a choice point — the swap changes the base, not the status.
      expect(state.flags.single.character, 'ሠ');
      expect(state.flags.single.siblings, ['ሰ']);
    },
  );

  blocTest<CheckerBloc, CheckerState>(
    'a swap while still in edit mode is ignored',
    build: buildBloc,
    act: (bloc) => bloc.add(SiblingSwapped(
      letter: repository.scan('ሰ').single,
      sibling: 'ሠ',
    )),
    expect: () => const <CheckerState>[],
  );

  blocTest<CheckerBloc, CheckerState>(
    'Mode B: a dominated spelling carries a suggestion with evidence',
    build: () => buildBloc(corpus: {'ሰላም': 5490, 'ሠላም': 50}),
    act: (bloc) => bloc.add(const TextChecked('ሠላም')),
    verify: (bloc) {
      final state = bloc.state as CheckerResult;
      final s = state.suggestions.single;
      expect(s.suggested, 'ሰላም');
      expect(state.likelyErrorIndices, {0});
      expect(state.suggestionAt(0), s);
      expect(state.suggestionAt(2), s); // any letter inside the word
      expect(state.suggestionAt(3), isNull); // past the word's end
    },
  );

  blocTest<CheckerBloc, CheckerState>(
    'Mode B: swapping to the common spelling dissolves the suggestion',
    build: () => buildBloc(corpus: {'ሰላም': 5490, 'ሠላም': 50}),
    act: (bloc) {
      bloc.add(const TextChecked('ሠላም'));
      bloc.add(SiblingSwapped(
        letter: repository.scan('ሠላም').single,
        sibling: 'ሰ',
      ));
    },
    verify: (bloc) {
      final state = bloc.state as CheckerResult;
      expect(state.text, 'ሰላም');
      expect(state.suggestions, isEmpty);
      expect(state.flags.single.character, 'ሰ'); // still a Mode A choice point
    },
  );

  blocTest<CheckerBloc, CheckerState>(
    'Fix all applies every suggestion at once and re-scans',
    build: () => buildBloc(
      corpus: {'ሰላም': 5490, 'ሠላም': 50, 'ሀገር': 5345, 'ሐገር': 2},
    ),
    act: (bloc) {
      bloc.add(const TextChecked('ሠላም ሐገር ነው'));
      bloc.add(const AllSuggestionsApplied());
    },
    verify: (bloc) {
      final state = bloc.state as CheckerResult;
      expect(state.text, 'ሰላም ሀገር ነው');
      expect(state.suggestions, isEmpty);
      expect(state.flags, hasLength(2)); // still ordinary choice points
    },
  );

  blocTest<CheckerBloc, CheckerState>(
    'Fix all with no suggestions emits nothing',
    build: () => buildBloc(corpus: {'ሰላም': 5490}),
    act: (bloc) {
      bloc.add(const TextChecked('ሰላም'));
      bloc.add(const AllSuggestionsApplied());
    },
    skip: 1, // the TextChecked emission
    expect: () => const <CheckerState>[],
  );

  blocTest<CheckerBloc, CheckerState>(
    'without the frequency list the result simply has no suggestions',
    build: buildBloc,
    act: (bloc) => bloc.add(const TextChecked('ሠላም')),
    verify: (bloc) {
      final state = bloc.state as CheckerResult;
      expect(state.flags, isNotEmpty);
      expect(state.suggestions, isEmpty);
    },
  );

  blocTest<CheckerBloc, CheckerState>(
    'Edit returns to edit mode',
    build: buildBloc,
    act: (bloc) {
      bloc.add(const TextChecked('ሰላም'));
      bloc.add(const EditingResumed());
    },
    verify: (bloc) {
      expect(bloc.state, const CheckerEditing());
    },
  );
}
