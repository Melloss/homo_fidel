import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../entities/homophone_family.dart';
import '../entities/word_suggestion.dart';
import '../repositories/word_frequency_repository.dart';

/// Mode B (spec §5): for each word containing a choice point, generate its
/// same-sound spelling variants and check them against the bundled frequency
/// list. When one variant overwhelmingly dominates the typed form in the
/// corpus, surface it as a suggestion.
///
/// "Overwhelmingly" is deliberate. The corpus is descriptive news prose, so a
/// mild imbalance proves nothing; the rule only fires when the evidence is
/// lopsided ([dominance]× the typed form's count and at least [minAttested]
/// occurrences). Everything else stays a plain Mode A choice point.
class SuggestCorrections
    implements UseCase<List<WordSuggestion>, SuggestCorrectionsParams> {
  /// A word is a run of Ethiopic syllables — the block's punctuation and
  /// digits start at U+1361, just above ፚ U+135A, so they never match.
  static final RegExp _word = RegExp(r'[ሀ-ፚ]+');

  /// A variant must appear at least this often before it is ever suggested.
  static const int minAttested = 10;

  /// ...and outnumber the typed spelling by this factor. (A typed word absent
  /// from the list counts as 0, so any variant with [minAttested] wins there.)
  static const int dominance = 20;

  /// Words whose variant space explodes (many family letters) are skipped
  /// rather than enumerated; by then the word is almost certainly compound
  /// enough that word-level frequencies carry no signal anyway.
  static const int maxVariants = 128;

  final List<HomophoneFamily> families;
  final WordFrequencyRepository repository;

  const SuggestCorrections({required this.families, required this.repository});

  @override
  List<WordSuggestion> call(SuggestCorrectionsParams params) {
    if (!repository.isAvailable) return const [];
    final suggestions = <WordSuggestion>[];
    for (final match in _word.allMatches(params.text)) {
      final suggestion = _suggestFor(match.group(0)!, match.start);
      if (suggestion != null) suggestions.add(suggestion);
    }
    return suggestions;
  }

  WordSuggestion? _suggestFor(String typed, int index) {
    // Per-letter alternatives; a letter outside every family has none.
    var variantCount = 1;
    final options = <List<String>>[];
    for (final rune in typed.runes) {
      final family = _familyOf(rune);
      final letter = String.fromCharCode(rune);
      if (family == null) {
        options.add([letter]);
      } else {
        final siblings = family.siblingsOf(rune);
        options.add([
          letter,
          for (final s in siblings) String.fromCharCode(s),
        ]);
        variantCount *= siblings.length + 1;
      }
    }
    if (variantCount == 1 || variantCount > maxVariants) return null;

    final typedCount = repository.frequencyOf(typed);
    String? best;
    var bestCount = 0;
    for (final variant in _expand(options)) {
      if (variant == typed) continue;
      final count = repository.frequencyOf(variant);
      if (count > bestCount) {
        best = variant;
        bestCount = count;
      }
    }
    if (best == null ||
        bestCount < minAttested ||
        bestCount < dominance * math.max(typedCount, 1)) {
      return null;
    }
    return WordSuggestion(
      index: index,
      typed: typed,
      suggested: best,
      typedCount: typedCount,
      suggestedCount: bestCount,
    );
  }

  HomophoneFamily? _familyOf(int codePoint) {
    for (final family in families) {
      if (family.contains(codePoint)) return family;
    }
    return null;
  }

  Iterable<String> _expand(List<List<String>> options) sync* {
    if (options.isEmpty) {
      yield '';
      return;
    }
    for (final rest in _expand(options.sublist(1))) {
      for (final first in options.first) {
        yield first + rest;
      }
    }
  }
}

class SuggestCorrectionsParams extends Equatable {
  final String text;

  const SuggestCorrectionsParams(this.text);

  @override
  List<Object?> get props => [text];
}
