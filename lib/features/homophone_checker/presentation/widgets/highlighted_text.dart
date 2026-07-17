import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/flagged_letter.dart';

/// The checked text, read-only, with every choice point highlighted and
/// tappable (spec §6). Each flagged character is its own [TextSpan] with a
/// [TapGestureRecognizer]; every fidäl is one code point, so no
/// grapheme-cluster handling is needed.
///
/// Stateful because span recognizers are not disposed by the framework —
/// this widget owns them and disposes them on rebuild and unmount.
class HighlightedText extends StatefulWidget {
  final String text;
  final List<FlaggedLetter> flags;

  /// Indices of letters a Mode B suggestion would change: rendered in the
  /// strong gold weight instead of the quiet wheat one (spec §14 — the
  /// weight difference between "you chose here" and "probably wrong" is the
  /// whole mitigation for highlight noise).
  final Set<int> likelyErrorIndices;

  final ValueChanged<FlaggedLetter> onLetterTap;

  const HighlightedText({
    super.key,
    required this.text,
    required this.flags,
    this.likelyErrorIndices = const {},
    required this.onLetterTap,
  });

  @override
  State<HighlightedText> createState() => _HighlightedTextState();
}

class _HighlightedTextState extends State<HighlightedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final dark = Theme.of(context).brightness == Brightness.dark;
    // The quiet Mode A weight — spec §14's mitigation for highlight noise.
    final highlight = dark ? AppColors.choicePointDark : AppColors.choicePoint;

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final flag in widget.flags) {
      if (flag.index > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, flag.index)));
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onLetterTap(flag);
      _recognizers.add(recognizer);
      final likely = widget.likelyErrorIndices.contains(flag.index);
      spans.add(
        TextSpan(
          text: flag.character,
          recognizer: recognizer,
          // Full-strength gold carries ink text (8.31:1 vs navy, better vs
          // ink) so the likely-error letters stay readable in dark mode too.
          style: likely
              ? const TextStyle(
                  backgroundColor: AppColors.likelyError,
                  color: AppColors.ink,
                )
              : TextStyle(backgroundColor: highlight),
        ),
      );
      cursor = flag.index + flag.character.length;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(children: spans),
      // Large and airy: the letters are tap targets, not just print.
      style: const TextStyle(fontSize: 22, height: 2.0),
    );
  }
}
