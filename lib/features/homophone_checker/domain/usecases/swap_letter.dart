import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../entities/flagged_letter.dart';

/// Replaces one flagged letter with a chosen same-sound sibling and returns
/// the new text.
///
/// Pure string surgery — no repository. The caller re-scans the result, since
/// swapping changes nothing about which positions are choice points but the
/// UI re-renders from a fresh scan anyway.
class SwapLetter implements UseCase<String, SwapLetterParams> {
  const SwapLetter();

  @override
  String call(SwapLetterParams params) {
    final SwapLetterParams(:text, :letter, :sibling) = params;
    final end = letter.index + letter.character.length;
    if (letter.index < 0 ||
        end > text.length ||
        text.substring(letter.index, end) != letter.character) {
      throw ArgumentError(
        'Stale swap: "${letter.character}" is not at index ${letter.index}',
      );
    }
    if (!letter.siblings.contains(sibling)) {
      throw ArgumentError(
        '"$sibling" is not a same-sound sibling of "${letter.character}"',
      );
    }
    return text.replaceRange(letter.index, end, sibling);
  }
}

class SwapLetterParams extends Equatable {
  /// The full text the letter lives in.
  final String text;

  /// The choice point being swapped, as returned by a scan of [text].
  final FlaggedLetter letter;

  /// The chosen replacement — must be one of [FlaggedLetter.siblings].
  final String sibling;

  const SwapLetterParams({
    required this.text,
    required this.letter,
    required this.sibling,
  });

  @override
  List<Object?> get props => [text, letter, sibling];
}
