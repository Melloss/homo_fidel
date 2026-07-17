import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/features/homophone_checker/data/datasources/family_local_data_source.dart';
import 'package:homofidel/features/homophone_checker/data/repositories/homophone_repository_impl.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/swap_letter.dart';

void main() {
  const repository = HomophoneRepositoryImpl(
    localDataSource: FamilyLocalDataSourceImpl(),
  );
  const swapLetter = SwapLetter();

  test('replaces the flagged letter with the chosen sibling', () {
    const text = 'ሰላም';
    final flag = repository.scan(text).single;
    final result = swapLetter(
      SwapLetterParams(text: text, letter: flag, sibling: 'ሠ'),
    );
    expect(result, 'ሠላም');
  });

  test('swaps at the right offset even after a surrogate pair', () {
    const text = '😀ሰላም';
    final flag = repository.scan(text).single;
    final result = swapLetter(
      SwapLetterParams(text: text, letter: flag, sibling: 'ሠ'),
    );
    expect(result, '😀ሠላም');
  });

  test('only touches the targeted occurrence when the letter repeats', () {
    const text = 'ሀሀሀ';
    final flags = repository.scan(text);
    final result = swapLetter(
      SwapLetterParams(text: text, letter: flags[1], sibling: 'ሐ'),
    );
    expect(result, 'ሀሐሀ');
  });

  test('a swap is reversible through a re-scan', () {
    const text = 'ጸሎት';
    final flag = repository.scan(text).single;
    final swapped = swapLetter(
      SwapLetterParams(text: text, letter: flag, sibling: 'ፀ'),
    );
    expect(swapped, 'ፀሎት');
    final back = swapLetter(
      SwapLetterParams(
        text: swapped,
        letter: repository.scan(swapped).single,
        sibling: 'ጸ',
      ),
    );
    expect(back, text);
  });

  test('rejects a sibling that is not same-sound for the letter', () {
    const text = 'ሰላም';
    final flag = repository.scan(text).single;
    expect(
      () => swapLetter(
        SwapLetterParams(text: text, letter: flag, sibling: 'ሐ'),
      ),
      throwsArgumentError,
    );
  });

  test('rejects a stale flag whose index no longer matches the text', () {
    const text = 'ሰላም';
    final flag = repository.scan(text).single;
    expect(
      () => swapLetter(
        SwapLetterParams(text: 'ላም', letter: flag, sibling: 'ሠ'),
      ),
      throwsArgumentError,
    );
  });
}
