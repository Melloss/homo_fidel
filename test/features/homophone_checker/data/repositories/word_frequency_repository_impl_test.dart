import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/features/homophone_checker/data/datasources/word_freq_local_data_source.dart';
import 'package:homofidel/features/homophone_checker/data/repositories/word_frequency_repository_impl.dart';

class _StubDataSource implements WordFreqLocalDataSource {
  final Map<String, int>? words;

  _StubDataSource(this.words);

  @override
  Future<Map<String, int>> load() async {
    final w = words;
    if (w == null) throw Exception('asset missing');
    return w;
  }
}

void main() {
  test('serves frequencies once loaded', () async {
    final repository = WordFrequencyRepositoryImpl(
      localDataSource: _StubDataSource({'ሰላም': 5490}),
    );
    expect(repository.isAvailable, isFalse); // not loaded yet
    await repository.load();
    expect(repository.isAvailable, isTrue);
    expect(repository.frequencyOf('ሰላም'), 5490);
    expect(repository.frequencyOf('የለም'), 0);
  });

  test('a failed load degrades to unavailable instead of throwing', () async {
    final repository = WordFrequencyRepositoryImpl(
      localDataSource: _StubDataSource(null),
    );
    await repository.load();
    expect(repository.isAvailable, isFalse);
    expect(repository.frequencyOf('ሰላም'), 0);
  });
}
