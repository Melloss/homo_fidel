import '../../domain/entities/flagged_letter.dart';
import '../../domain/repositories/homophone_repository.dart';
import '../datasources/family_local_data_source.dart';

class HomophoneRepositoryImpl implements HomophoneRepository {
  final FamilyLocalDataSource localDataSource;

  const HomophoneRepositoryImpl({required this.localDataSource});

  @override
  List<FlaggedLetter> scan(String text) {
    final families = localDataSource.families;
    final flags = <FlaggedLetter>[];
    var index = 0; // UTF-16 code-unit offset, see FlaggedLetter.index
    for (final codePoint in text.runes) {
      for (final family in families) {
        final order = family.orderOf(codePoint);
        if (order != null) {
          flags.add(
            FlaggedLetter(
              index: index,
              character: String.fromCharCode(codePoint),
              family: family,
              order: order,
              siblings: [
                for (final sibling in family.siblingsOf(codePoint))
                  String.fromCharCode(sibling),
              ],
            ),
          );
          break; // The families are disjoint code-point ranges.
        }
      }
      index += codePoint > 0xFFFF ? 2 : 1;
    }
    return flags;
  }
}
