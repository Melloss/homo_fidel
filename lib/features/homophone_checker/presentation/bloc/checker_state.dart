part of 'checker_bloc.dart';

sealed class CheckerState extends Equatable {
  const CheckerState();

  @override
  List<Object?> get props => [];
}

/// Edit mode: the TextField owns the text; the bloc holds nothing.
final class CheckerEditing extends CheckerState {
  const CheckerEditing();
}

/// Checked mode: [text] rendered read-only with [flags] highlighted and any
/// Mode B [suggestions] (empty when the frequency list is unavailable or
/// nothing dominates) marked in the stronger weight.
final class CheckerResult extends CheckerState {
  final String text;
  final List<FlaggedLetter> flags;
  final List<WordSuggestion> suggestions;

  const CheckerResult({
    required this.text,
    required this.flags,
    this.suggestions = const [],
  });

  /// Text indices of letters a suggestion would change — the ones the UI
  /// paints with the strong likely-error weight instead of the quiet one.
  Set<int> get likelyErrorIndices => {
        for (final suggestion in suggestions) ...suggestion.changedIndices,
      };

  /// The suggestion whose word covers the letter at [index], if any.
  WordSuggestion? suggestionAt(int index) {
    for (final suggestion in suggestions) {
      if (index >= suggestion.index &&
          index < suggestion.index + suggestion.typed.length) {
        return suggestion;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [text, flags, suggestions];
}
