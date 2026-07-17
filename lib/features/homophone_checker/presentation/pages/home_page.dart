import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/checker_bloc.dart';
import '../../domain/entities/flagged_letter.dart';
import '../widgets/highlighted_text.dart';
import '../widgets/swap_sheet.dart';

/// The one screen (spec §6): paste/type → Check → highlighted result →
/// tap to swap → Copy. No onboarding, no menus.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  /// Pre-filled example so the client can test in one tap (spec §6). Every
  /// family appears at least once, in both directions where there are two
  /// bases: ሰ/ሠ, ሀ/ሐ, ፀ/ጸ, አ/ዐ.
  static const sampleText = 'ሰላም ለሀገራችን። ፀሐይ ስትወጣ አበበ በጸሎት ላይ ነበር። '
      'የሠራተኛው ዐይን በተስፋ ተሞላ።';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onLetterTap(FlaggedLetter letter) async {
    final bloc = context.read<CheckerBloc>();
    final state = bloc.state;
    final sibling = await SwapSheet.show(
      context,
      letter,
      suggestion:
          state is CheckerResult ? state.suggestionAt(letter.index) : null,
    );
    if (sibling != null) {
      bloc.add(SiblingSwapped(letter: letter, sibling: sibling));
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('ተቀድቷል — copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Homofidäl')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocConsumer<CheckerBloc, CheckerState>(
            listener: (context, state) {
              // After a swap the corrected text must survive returning to
              // edit mode, so the controller follows the bloc.
              if (state is CheckerResult) _controller.text = state.text;
            },
            builder: (context, state) => switch (state) {
              CheckerEditing() => _buildEditView(context),
              CheckerResult() => _buildResultView(context, state),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEditView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 20, height: 1.8),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'የአማርኛ ጽሑፍ እዚህ ይለጥፉ ወይም ይጻፉ…',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _controller.text = HomePage.sampleText,
              icon: const Icon(Icons.article_outlined),
              label: const Text('ናሙና'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => context
                  .read<CheckerBloc>()
                  .add(TextChecked(_controller.text)),
              icon: const Icon(Icons.search),
              label: const Text('አረጋግጥ'),
            ),
          ],
        ),
      ],
    );
  }

  String _summaryLine(CheckerResult state) {
    if (state.flags.isEmpty) return 'No choice points found.';
    final points = '${state.flags.length} choice point'
        '${state.flags.length == 1 ? '' : 's'}';
    final likely = state.suggestions.isEmpty
        ? ''
        : ' · ${state.suggestions.length} likely slip'
            '${state.suggestions.length == 1 ? '' : 's'} in gold';
    return '$points$likely — tap a highlighted letter to swap it';
  }

  Widget _buildResultView(BuildContext context, CheckerResult state) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _summaryLine(state),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: HighlightedText(
              text: state.text,
              flags: state.flags,
              likelyErrorIndices: state.likelyErrorIndices,
              onLetterTap: _onLetterTap,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  context.read<CheckerBloc>().add(const EditingResumed()),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('አርም'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _copy(state.text),
              icon: const Icon(Icons.copy),
              label: const Text('ቅዳ'),
            ),
          ],
        ),
      ],
    );
  }
}
