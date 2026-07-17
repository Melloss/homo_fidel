import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'core/theme/app_theme.dart';
import 'injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicense();
  await di.init();
  runApp(const HomofidelApp());
}

/// The bundled Ethiopic font is SIL OFL 1.1, which requires the licence to be
/// distributed with it. Flutter auto-collects LICENSE files from packages but
/// not from bundled assets, so this registers it by hand.
void _registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['NotoSansEthiopic'],
      await rootBundle.loadString('assets/fonts/OFL.txt'),
    );
  });
}

/// App shell. The one screen (input, Check/Copy, highlighted result, swap
/// sheet) lands in features/homophone_checker/presentation/pages/home_page.dart
/// behind a BlocProvider — see spec §6.
class HomofidelApp extends StatelessWidget {
  const HomofidelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomoFidel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(child: Text('ፊደል')),
      ),
    );
  }
}
