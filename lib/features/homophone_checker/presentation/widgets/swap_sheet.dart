import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/flagged_letter.dart';
import '../../domain/entities/word_suggestion.dart';

/// Bottom sheet for one tapped choice point: the letter, its family sound,
/// and each same-sound sibling rendered large (spec §6). Pops with the chosen
/// sibling, or null when dismissed.
///
/// When a Mode B [suggestion] covers this letter, the sibling the corpus
/// favours gets a star and the evidence is shown as plain counts — the app
/// presents the numbers, the writer makes the call (assist, not authority).
class SwapSheet extends StatelessWidget {
  final FlaggedLetter letter;
  final WordSuggestion? suggestion;

  const SwapSheet({super.key, required this.letter, this.suggestion});

  static Future<String?> show(
    BuildContext context,
    FlaggedLetter letter, {
    WordSuggestion? suggestion,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SwapSheet(letter: letter, suggestion: suggestion),
    );
  }

  /// The sibling the suggestion recommends at this letter, if it recommends
  /// changing this letter at all (the word may need a change elsewhere).
  String? get _recommended {
    final s = suggestion;
    if (s == null) return null;
    final here = s.characterAt(letter.index);
    return here == letter.character ? null : here;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = suggestion;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Same-sound letters',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${letter.character} — the ${letter.family.sound} family · tap a letter to use it',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final sibling in letter.siblings) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _SiblingButton(
                      sibling: sibling,
                      recommended: sibling == _recommended,
                      onTap: () => Navigator.of(context).pop(sibling),
                    ),
                  ),
                ],
              ],
            ),
            if (s != null) ...[
              const SizedBox(height: 16),
              Text(
                'News corpus:  ${s.typed} ×${s.typedCount}   ·   '
                '${s.suggested} ×${s.suggestedCount}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SiblingButton extends StatelessWidget {
  final String sibling;
  final bool recommended;
  final VoidCallback onTap;

  const _SiblingButton({
    required this.sibling,
    required this.recommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 88,
          height: 88,
          decoration: recommended
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold, width: 3),
                )
              : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                sibling,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              if (recommended)
                const Positioned(
                  top: 6,
                  right: 8,
                  child: Icon(Icons.star, size: 18, color: AppColors.gold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
