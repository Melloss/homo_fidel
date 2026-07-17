import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/features/homophone_checker/data/datasources/family_local_data_source.dart';

void main() {
  const dataSource = FamilyLocalDataSourceImpl();

  test('ships exactly the four canonical families of spec §4', () {
    final byId = {for (final f in dataSource.families) f.id: f.bases};
    expect(byId, {
      'H': [0x1200, 0x1210, 0x1280], // ሀ ሐ ኀ
      'S': [0x1230, 0x1220], // ሰ ሠ
      'TS': [0x1338, 0x1340], // ጸ ፀ
      'A': [0x12A0, 0x12D0], // አ ዐ
    });
  });

  test('family ranges are disjoint — no code point belongs to two families',
      () {
    final seen = <int>{};
    for (final family in dataSource.families) {
      for (final base in family.bases) {
        for (var cp = base; cp < base + 7; cp++) {
          expect(seen.add(cp), isTrue,
              reason: 'U+${cp.toRadixString(16)} appears twice');
        }
      }
    }
  });
}
