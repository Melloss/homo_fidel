import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/features/homophone_checker/data/datasources/word_freq_local_data_source.dart';

/// Loads the real shipped asset — this is the integrity check that the file
/// tool/build_word_freq.py generated actually parses and carries plausible
/// Amharic news frequencies.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled word_freq.json parses and looks like Amharic news', () async {
    final words = await WordFreqLocalDataSourceImpl().load();
    expect(words.length, greaterThan(50000));
    // Everyday words the corpus must know, with the common spelling dominant.
    expect(words['ሰላም']!, greaterThan(1000));
    expect(words['ኢትዮጵያ']!, greaterThan(10000));
    expect(words['ሰላም']!, greaterThan(words['ሠላም'] ?? 0));
    // The generator only keeps words containing a family letter.
    expect(words.containsKey('መንግስት'), isTrue); // has ስ (S family)
    expect(words.containsKey('ቀን'), isFalse); // no family letter
  });
}
