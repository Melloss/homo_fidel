import 'package:equatable/equatable.dart';

import 'homophone_family.dart';

/// A "choice point": one character in the scanned text that belongs to a
/// homophone family and could therefore be a same-sound slip.
class FlaggedLetter extends Equatable {
  /// UTF-16 code-unit offset of [character] in the scanned string.
  ///
  /// Code units, not runes, so the value plugs straight into
  /// `String.replaceRange` and text-span mapping even when earlier characters
  /// (e.g. emoji) occupy two code units. Every fidäl itself is a single
  /// BMP code point, so [character] always has length 1.
  final int index;

  /// The flagged character itself.
  final String character;

  /// The family it belongs to.
  final HomophoneFamily family;

  /// Vowel order (0–6) within its base letter.
  final int order;

  /// Same-sound alternatives: same vowel order, the family's other bases.
  final List<String> siblings;

  const FlaggedLetter({
    required this.index,
    required this.character,
    required this.family,
    required this.order,
    required this.siblings,
  });

  @override
  List<Object?> get props => [index, character, family, order, siblings];
}
