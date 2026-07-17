import 'package:flutter/material.dart';

import '../../domain/entities/flagged_letter.dart';

/// Bottom sheet for one tapped choice point: the letter, its family sound,
/// and each same-sound sibling rendered large (spec §6). Pops with the chosen
/// sibling, or null when dismissed.
class SwapSheet extends StatelessWidget {
  final FlaggedLetter letter;

  const SwapSheet({super.key, required this.letter});

  static Future<String?> show(BuildContext context, FlaggedLetter letter) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SwapSheet(letter: letter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ተመሳሳይ ድምፅ ያላቸው ፊደላት',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${letter.character} — the ${letter.family.sound} family',
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
                      onTap: () => Navigator.of(context).pop(sibling),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SiblingButton extends StatelessWidget {
  final String sibling;
  final VoidCallback onTap;

  const _SiblingButton({required this.sibling, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 88,
          height: 88,
          child: Center(
            child: Text(
              sibling,
              style: theme.textTheme.displayMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
