import '../../domain/repositories/word_frequency_repository.dart';
import '../datasources/word_freq_local_data_source.dart';

/// Holds the frequency list in memory once [load] completes.
///
/// Failure is a supported state, not an error path: if the asset is missing
/// or corrupt, [isAvailable] stays false, Mode B silently contributes no
/// suggestions, and Mode A is untouched.
class WordFrequencyRepositoryImpl implements WordFrequencyRepository {
  final WordFreqLocalDataSource localDataSource;

  Map<String, int>? _words;

  WordFrequencyRepositoryImpl({required this.localDataSource});

  Future<void> load() async {
    try {
      _words = await localDataSource.load();
    } catch (_) {
      _words = null;
    }
  }

  @override
  bool get isAvailable => _words != null;

  @override
  int frequencyOf(String word) => _words?[word] ?? 0;
}
