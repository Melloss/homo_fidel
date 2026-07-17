/// Domain contract for the Mode B word-frequency lookup.
abstract interface class WordFrequencyRepository {
  /// Whether the bundled list is loaded and usable.
  ///
  /// Mode B is an enhancement, never a prerequisite: when this is false the
  /// engine simply returns no suggestions and Mode A keeps working.
  bool get isAvailable;

  /// Corpus frequency of [word]; 0 when it is absent from the list.
  int frequencyOf(String word);
}
