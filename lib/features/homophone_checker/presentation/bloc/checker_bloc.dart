import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/flagged_letter.dart';
import '../../domain/entities/word_suggestion.dart';
import '../../domain/usecases/scan_text.dart';
import '../../domain/usecases/suggest_corrections.dart';
import '../../domain/usecases/swap_letter.dart';

part 'checker_event.dart';
part 'checker_state.dart';

/// Drives the one screen between its two modes (spec §6): edit mode, where a
/// TextField owns the text, and checked mode, where the scanned text renders
/// read-only with tappable choice points (Mode A) and, when the frequency
/// list is available, likely-error suggestions layered on top (Mode B).
class CheckerBloc extends Bloc<CheckerEvent, CheckerState> {
  final ScanText scanText;
  final SwapLetter swapLetter;
  final SuggestCorrections suggestCorrections;

  CheckerBloc({
    required this.scanText,
    required this.swapLetter,
    required this.suggestCorrections,
  }) : super(const CheckerEditing()) {
    on<TextChecked>(_onTextChecked);
    on<SiblingSwapped>(_onSiblingSwapped);
    on<EditingResumed>(_onEditingResumed);
  }

  CheckerResult _check(String text) => CheckerResult(
        text: text,
        flags: scanText(ScanTextParams(text)),
        suggestions: suggestCorrections(SuggestCorrectionsParams(text)),
      );

  void _onTextChecked(TextChecked event, Emitter<CheckerState> emit) {
    emit(_check(event.text));
  }

  void _onSiblingSwapped(SiblingSwapped event, Emitter<CheckerState> emit) {
    final current = state;
    if (current is! CheckerResult) return;
    final newText = swapLetter(
      SwapLetterParams(
        text: current.text,
        letter: event.letter,
        sibling: event.sibling,
      ),
    );
    // Re-scan rather than patch the flag list: later indices are unchanged
    // (siblings are same-length), but a fresh scan keeps one source of truth —
    // and a swap can legitimately dissolve or create a Mode B suggestion.
    emit(_check(newText));
  }

  void _onEditingResumed(EditingResumed event, Emitter<CheckerState> emit) {
    emit(const CheckerEditing());
  }
}
