import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/features/homophone_checker/data/datasources/family_local_data_source.dart';
import 'package:homofidel/features/homophone_checker/data/repositories/homophone_repository_impl.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/scan_text.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/swap_letter.dart';
import 'package:homofidel/features/homophone_checker/presentation/bloc/checker_bloc.dart';

void main() {
  // Real use cases over the real tables: the engine is deterministic and
  // fast, so mocking it would only test the mock.
  const repository = HomophoneRepositoryImpl(
    localDataSource: FamilyLocalDataSourceImpl(),
  );
  const scanText = ScanText(repository);
  const swapLetter = SwapLetter();

  CheckerBloc buildBloc() =>
      CheckerBloc(scanText: scanText, swapLetter: swapLetter);

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
