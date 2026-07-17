import 'package:equatable/equatable.dart';

/// Mode B: evidence that a same-sound spelling of one word is far more common
/// in the reference corpus than the spelling the writer used.
///
/// Deliberately *not* named an error. The bundled list is descriptive — it
/// counts how Ethiopian newsrooms actually spell — and modern usage sometimes
/// departs from traditional orthography. So this entity carries the counts
/// that justify the suggestion, and the UI shows them, rather than asserting a
/// correctness the data cannot support (spec §14: "correct is contextual").
class WordSuggestion extends Equatable {
  /// UTF-16 code-unit index where the word starts in the scanned text.
  final int index;

  /// The word as typed.
  final String typed;

  /// The same-sound variant that dominates the corpus.
  final String suggested;

  /// Corpus frequency of [typed]; 0 when absent from the list.
  final int typedCount;

  /// Corpus frequency of [suggested]. Always > [typedCount].
  final int suggestedCount;

  const WordSuggestion({
    required this.index,
    required this.typed,
    required this.suggested,
    required this.typedCount,
    required this.suggestedCount,
  });

  /// Absolute indices of the letters [suggested] would change.
  ///
  /// [typed] and [suggested] always have the same length: a sibling swaps one
  /// base for another within the same seven-order row, and every fidäl is a
  /// single BMP code unit.
  List<int> get changedIndices => [
        for (var i = 0; i < typed.length; i++)
          if (typed[i] != suggested[i]) index + i,
      ];

  /// The letter [suggested] carries at absolute [textIndex].
  String characterAt(int textIndex) => suggested[textIndex - index];

  @override
  List<Object?> get props => [index, typed, suggested, typedCount, suggestedCount];
}
