import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/features/homophone_checker/domain/entities/flagged_letter.dart';
import 'package:homofidel/features/homophone_checker/domain/entities/homophone_family.dart';
import 'package:homofidel/features/homophone_checker/domain/repositories/homophone_repository.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/scan_text.dart';
import 'package:mocktail/mocktail.dart';

class MockHomophoneRepository extends Mock implements HomophoneRepository {}

void main() {
  late MockHomophoneRepository repository;
  late ScanText scanText;

  setUp(() {
    repository = MockHomophoneRepository();
    scanText = ScanText(repository);
  });

  test('delegates to the repository and returns its flags unchanged', () {
    const family =
        HomophoneFamily(id: 'S', sound: '/s/', bases: [0x1230, 0x1220]);
    const flags = [
      FlaggedLetter(
        index: 0,
        character: 'ሳ',
        family: family,
        order: 3,
        siblings: ['ሣ'],
      ),
    ];
    when(() => repository.scan('ሳ')).thenReturn(flags);

    expect(scanText(const ScanTextParams('ሳ')), flags);
    verify(() => repository.scan('ሳ')).called(1);
  });
}
