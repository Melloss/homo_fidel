import 'package:flutter/material.dart';

import 'injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const HomofidelApp());
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B2A4A)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('HomoFidel')),
      ),
    );
  }
}
