import '../../domain/entities/homophone_family.dart';

/// Supplies the homophone family tables.
abstract interface class FamilyLocalDataSource {
  List<HomophoneFamily> get families;
}

/// The four canonical families (spec §4), hand-written and verified against
/// the Unicode Ethiopic block — deliberately not the `amharic_homophones`
/// package, which depends on the Flutter SDK and does normalization rather
/// than family/sibling mapping (see NOTES.md).
class FamilyLocalDataSourceImpl implements FamilyLocalDataSource {
  const FamilyLocalDataSourceImpl();

  static const List<HomophoneFamily> _families = [
    HomophoneFamily(id: 'H', sound: '/h/', bases: [0x1200, 0x1210, 0x1280]),
    HomophoneFamily(id: 'S', sound: '/s/', bases: [0x1230, 0x1220]),
    HomophoneFamily(id: 'TS', sound: "/ts'/", bases: [0x1338, 0x1340]),
    HomophoneFamily(id: 'A', sound: '/ʔ ~ a/', bases: [0x12A0, 0x12D0]),
  ];

  @override
  List<HomophoneFamily> get families => _families;
}
