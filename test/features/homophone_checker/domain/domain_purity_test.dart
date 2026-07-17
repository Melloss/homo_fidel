import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Spec §7: the domain layer must stay pure Dart so the engine can run
/// without a widget harness and be reused outside Flutter (e.g. in an IME).
/// This guards the constraint mechanically instead of by convention.
void main() {
  test('domain layer has no Flutter imports', () {
    final domainDir =
        Directory('lib/features/homophone_checker/domain');
    final offenders = domainDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('package:flutter/'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty,
        reason: 'Flutter leaked into the pure-Dart domain layer');
  });
}
