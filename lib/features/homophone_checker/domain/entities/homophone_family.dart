import 'package:equatable/equatable.dart';

/// A set of Ge'ez base letters that share one modern Amharic sound.
///
/// Within the Ethiopic block, every base letter's seven vowel orders occupy
/// seven consecutive code points, so family membership, vowel order, and
/// same-sound siblings are all arithmetic on the code point (spec §5):
///
///     order   = codePoint - base
///     sibling = otherBase + order
class HomophoneFamily extends Equatable {
  /// Stable identifier: 'H', 'S', 'TS', 'A'.
  final String id;

  /// The shared sound, e.g. '/h/'.
  final String sound;

  /// First-order (ä) code points of each base letter, e.g. 0x1200 for ሀ.
  final List<int> bases;

  const HomophoneFamily({
    required this.id,
    required this.sound,
    required this.bases,
  });

  /// Vowel orders per base letter. The 8th slot (base + 7) is a real,
  /// assigned, *different* letter — the labiovelar variant (ሷ, ሗ, ኧ…) — so
  /// the valid range is base..base + 6 inclusive, never base + 7.
  static const int orderCount = 7;

  /// The base letter [codePoint] falls under, or null if it is not in this
  /// family.
  int? baseOf(int codePoint) {
    for (final base in bases) {
      if (codePoint >= base && codePoint <= base + orderCount - 1) {
        return base;
      }
    }
    return null;
  }

  /// Whether [codePoint] is one of this family's letters (any vowel order).
  bool contains(int codePoint) => baseOf(codePoint) != null;

  /// Vowel order (0–6) of [codePoint] within its base, or null if it is not
  /// in this family.
  int? orderOf(int codePoint) {
    final base = baseOf(codePoint);
    return base == null ? null : codePoint - base;
  }

  /// Same-sound alternatives for [codePoint]: the same vowel order under
  /// every *other* base in the family. Empty if it is not in this family.
  List<int> siblingsOf(int codePoint) {
    final base = baseOf(codePoint);
    if (base == null) return const [];
    final order = codePoint - base;
    return [
      for (final other in bases)
        if (other != base) other + order,
    ];
  }

  @override
  List<Object?> get props => [id, sound, bases];
}
