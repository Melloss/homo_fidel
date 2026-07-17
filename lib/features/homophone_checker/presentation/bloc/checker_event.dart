part of 'checker_bloc.dart';

sealed class CheckerEvent extends Equatable {
  const CheckerEvent();

  @override
  List<Object?> get props => [];
}

/// Check pressed with the text as currently typed.
final class TextChecked extends CheckerEvent {
  final String text;

  const TextChecked(this.text);

  @override
  List<Object?> get props => [text];
}

/// A sibling chosen in the swap sheet for a flagged letter.
final class SiblingSwapped extends CheckerEvent {
  final FlaggedLetter letter;
  final String sibling;

  const SiblingSwapped({required this.letter, required this.sibling});

  @override
  List<Object?> get props => [letter, sibling];
}

/// Fix all pressed: apply every Mode B suggestion in one go.
final class AllSuggestionsApplied extends CheckerEvent {
  const AllSuggestionsApplied();
}

/// Edit pressed on the result view — back to the TextField.
final class EditingResumed extends CheckerEvent {
  const EditingResumed();
}
