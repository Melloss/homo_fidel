import 'package:homofidel/features/homophone_checker/domain/repositories/word_frequency_repository.dart';

/// Map-backed stand-in for the bundled frequency list, so suggestion tests
/// control the corpus instead of depending on the shipped asset's counts.
class FakeWordFrequencyRepository implements WordFrequencyRepository {
  final Map<String, int> counts;

  @override
  final bool isAvailable;

  const FakeWordFrequencyRepository(this.counts, {this.isAvailable = true});

  const FakeWordFrequencyRepository.unavailable()
      : counts = const {},
        isAvailable = false;

  @override
  int frequencyOf(String word) => counts[word] ?? 0;
}
