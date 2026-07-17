import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/features/homophone_checker/data/datasources/family_local_data_source.dart';
import 'package:homofidel/features/homophone_checker/data/repositories/homophone_repository_impl.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/scan_text.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/swap_letter.dart';
import 'package:homofidel/features/homophone_checker/presentation/bloc/checker_bloc.dart';
import 'package:homofidel/features/homophone_checker/presentation/pages/home_page.dart';
import 'package:homofidel/features/homophone_checker/presentation/widgets/highlighted_text.dart';
import 'package:homofidel/features/homophone_checker/presentation/widgets/swap_sheet.dart';

/// Full-flow widget tests over the real engine — no mocks, per the spec's
/// "the engine is deterministic, so test it for real" stance.
void main() {
  Widget buildApp() {
    const repository = HomophoneRepositoryImpl(
      localDataSource: FamilyLocalDataSourceImpl(),
    );
    return MaterialApp(
      home: BlocProvider(
        create: (_) => CheckerBloc(
          scanText: const ScanText(repository),
          swapLetter: const SwapLetter(),
        ),
        child: const HomePage(),
      ),
    );
  }

  /// Finds the recognizer attached to the [n]th flagged span and taps it.
  /// TextSpan hit-testing by pixel is glyph-metric dependent under the test
  /// font, so invoke the recognizer directly — it is exactly what a tap runs.
  void tapFlaggedLetter(WidgetTester tester, {int which = 0}) {
    final richText = tester.widget<Text>(
      find.descendant(
        of: find.byType(HighlightedText),
        matching: find.byType(Text),
      ),
    );
    final recognizers = <TapGestureRecognizer>[];
    (richText.textSpan as TextSpan).visitChildren((span) {
      final recognizer = (span as TextSpan).recognizer;
      if (recognizer is TapGestureRecognizer) recognizers.add(recognizer);
      return true;
    });
    recognizers[which].onTap!();
  }

  testWidgets('boots in edit mode with input, sample, and Check', (tester) async {
    await tester.pumpWidget(buildApp());
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('ናሙና'), findsOneWidget);
    expect(find.text('አረጋግጥ'), findsOneWidget);
  });

  testWidgets('sample button pre-fills the example text', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('ናሙና'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, HomePage.sampleText);
  });

  testWidgets('Check renders the highlighted result with a count', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'ሰላም ፀሐይ');
    await tester.tap(find.text('አረጋግጥ'));
    await tester.pumpAndSettle();

    expect(find.byType(HighlightedText), findsOneWidget);
    expect(
      find.text('3 choice points — tap a highlighted letter to swap it'),
      findsOneWidget,
    );
  });

  testWidgets('text without choice points says so honestly', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'መልካም ቀን');
    await tester.tap(find.text('አረጋግጥ'));
    await tester.pumpAndSettle();

    expect(find.text('No choice points found.'), findsOneWidget);
  });

  testWidgets('tapping a flagged letter opens the swap sheet with its siblings',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'ሰላም');
    await tester.tap(find.text('አረጋግጥ'));
    await tester.pumpAndSettle();

    tapFlaggedLetter(tester);
    await tester.pumpAndSettle();

    expect(find.byType(SwapSheet), findsOneWidget);
    expect(find.text('ሠ'), findsOneWidget);
  });

  testWidgets('choosing a sibling swaps the letter in the result',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'ሰላም');
    await tester.tap(find.text('አረጋግጥ'));
    await tester.pumpAndSettle();

    tapFlaggedLetter(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ሠ'));
    await tester.pumpAndSettle();

    expect(find.byType(SwapSheet), findsNothing);
    final richText = tester.widget<Text>(
      find.descendant(
        of: find.byType(HighlightedText),
        matching: find.byType(Text),
      ),
    );
    expect(richText.textSpan!.toPlainText(), 'ሠላም');
  });

  testWidgets('Edit returns to the field with the swapped text preserved',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'ሰላም');
    await tester.tap(find.text('አረጋግጥ'));
    await tester.pumpAndSettle();
    tapFlaggedLetter(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ሠ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('አርም'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'ሠላም');
  });
}
