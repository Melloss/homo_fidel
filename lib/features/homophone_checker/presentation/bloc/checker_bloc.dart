import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/flagged_letter.dart';
import '../../domain/usecases/scan_text.dart';
import '../../domain/usecases/swap_letter.dart';

part 'checker_event.dart';
part 'checker_state.dart';

/// Drives the one screen between its two modes (spec §6): edit mode, where a
/// TextField owns the text, and checked mode, where the scanned text renders
/// read-only with tappable choice points.
class CheckerBloc extends Bloc<CheckerEvent, CheckerState> {
  final ScanText scanText;
  final SwapLetter swapLetter;

  CheckerBloc({required this.scanText, required this.swapLetter})
      : super(const CheckerEditing()) {
    on<TextChecked>(_onTextChecked);
    on<SiblingSwapped>(_onSiblingSwapped);
    on<EditingResumed>(_onEditingResumed);
  }

  void _onTextChecked(TextChecked event, Emitter<CheckerState> emit) {
    emit(
      CheckerResult(
        text: event.text,
        flags: scanText(ScanTextParams(event.text)),
      ),
    );
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
    // (siblings are same-length), but a fresh scan keeps one source of truth.
    emit(
      CheckerResult(
        text: newText,
        flags: scanText(ScanTextParams(newText)),
      ),
    );
  }

  void _onEditingResumed(EditingResumed event, Emitter<CheckerState> emit) {
    emit(const CheckerEditing());
  }
}
