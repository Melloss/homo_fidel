import '../entities/flagged_letter.dart';

/// Domain contract for homophone detection; the data layer implements it.
abstract interface class HomophoneRepository {
  /// Every choice point in [text], in order of appearance. Text with no
  /// family letters (including empty text) yields an empty list.
  List<FlaggedLetter> scan(String text);
}
