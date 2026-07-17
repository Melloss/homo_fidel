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

/// Checked mode: [text] rendered read-only with [flags] highlighted.
final class CheckerResult extends CheckerState {
  final String text;
  final List<FlaggedLetter> flags;

  const CheckerResult({required this.text, required this.flags});

  @override
  List<Object?> get props => [text, flags];
}
