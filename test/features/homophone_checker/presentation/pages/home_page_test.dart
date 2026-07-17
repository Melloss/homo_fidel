import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/core/theme/app_colors.dart';
import 'package:homofidel/features/homophone_checker/data/datasources/family_local_data_source.dart';
import 'package:homofidel/features/homophone_checker/data/repositories/homophone_repository_impl.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/scan_text.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/suggest_corrections.dart';
import 'package:homofidel/features/homophone_checker/domain/usecases/swap_letter.dart';
import 'package:homofidel/features/homophone_checker/presentation/bloc/checker_bloc.dart';
import 'package:homofidel/features/homophone_checker/presentation/pages/home_page.dart';
import 'package:homofidel/features/homophone_checker/presentation/widgets/highlighted_text.dart';
import 'package:homofidel/features/homophone_checker/presentation/widgets/swap_sheet.dart';

import '../../helpers/fake_word_frequency_repository.dart';

/// Full-flow widget tests over the real engine — no mocks, per the spec's
/// "the engine is deterministic, so test it for real" stance. Only the Mode B
/// corpus is faked ([corpus] null = frequency list unavailable, Mode A only).
void main() {
  Widget buildApp({Map<String, int>? corpus}) {
    const repository = HomophoneRepositoryImpl(
      localDataSource: FamilyLocalDataSourceImpl(),
    );
    return MaterialApp(
      home: BlocProvider(
        create: (_) => CheckerBloc(
          scanText: const ScanText(repository),
          swapLetter: const SwapLetter(),
          suggestCorrections: SuggestCorrections(
            families: const FamilyLocalDataSourceImpl().families,
            repository: corpus == null
                ? const FakeWordFrequencyRepository.unavailable()
                : FakeWordFrequencyRepository(corpus),
          ),
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
    expect(find.text('Sample'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
  });

  testWidgets('sample button pre-fills the example text', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Sample'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, HomePage.sampleText);
  });

  testWidgets('Check renders the highlighted result with a count', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'ሰላም ፀሐይ');
    await tester.tap(find.text('Check'));
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
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    expect(find.text('No choice points found.'), findsOneWidget);
  });

  testWidgets('tapping a flagged letter opens the swap sheet with its siblings',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'ሰላም');
    await tester.tap(find.text('Check'));
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
    await tester.tap(find.text('Check'));
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

  group('Mode B', () {
    const corpus = {'ሰላም': 5490, 'ሠላም': 50};

    testWidgets('a likely slip is counted and painted in the strong gold',
        (tester) async {
      await tester.pumpWidget(buildApp(corpus: corpus));
      await tester.enterText(find.byType(TextField), 'ሠላም');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(
        find.text(
            '1 choice point · 1 likely slip in gold — tap a highlighted letter to swap it'),
        findsOneWidget,
      );
      final richText = tester.widget<Text>(
        find.descendant(
          of: find.byType(HighlightedText),
          matching: find.byType(Text),
        ),
      );
      final styles = <TextStyle?>[];
      (richText.textSpan as TextSpan).visitChildren((span) {
        if ((span as TextSpan).recognizer != null) styles.add(span.style);
        return true;
      });
      expect(styles.single?.backgroundColor, AppColors.likelyError);
    });

    testWidgets('the sheet stars the corpus pick and shows the evidence',
        (tester) async {
      await tester.pumpWidget(buildApp(corpus: corpus));
      await tester.enterText(find.byType(TextField), 'ሠላም');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      tapFlaggedLetter(tester);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.textContaining('ሠላም ×50'), findsOneWidget);
      expect(find.textContaining('ሰላም ×5490'), findsOneWidget);
    });

    testWidgets('an ordinary choice point gets no star and no evidence line',
        (tester) async {
      await tester.pumpWidget(buildApp(corpus: corpus));
      await tester.enterText(find.byType(TextField), 'ሰላም');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      tapFlaggedLetter(tester);
      await tester.pumpAndSettle();

      expect(find.byType(SwapSheet), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.textContaining('News corpus'), findsNothing);
    });

    testWidgets('Fix all is disabled when nothing is likely wrong',
        (tester) async {
      await tester.pumpWidget(buildApp(corpus: corpus));
      await tester.enterText(find.byType(TextField), 'ሰላም');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      // FilledButton.tonalIcon builds a private FilledButton subclass, so
      // match by predicate rather than exact type.
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Fix all'),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('Fix all applies every suggestion in one tap', (tester) async {
      await tester.pumpWidget(buildApp(corpus: {
        ...corpus,
        'ሀገር': 5345,
        'ሐገር': 2,
      }));
      await tester.enterText(find.byType(TextField), 'ሠላም ሐገር');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 likely slips'), findsOneWidget);

      await tester.tap(find.text('Fix all'));
      await tester.pumpAndSettle();

      final richText = tester.widget<Text>(
        find.descendant(
          of: find.byType(HighlightedText),
          matching: find.byType(Text),
        ),
      );
      expect(richText.textSpan!.toPlainText(), 'ሰላም ሀገር');
      // Summary drops the gold segment; the snackbar reports the fix count.
      expect(
        find.text('2 choice points — tap a highlighted letter to swap it'),
        findsOneWidget,
      );
      expect(find.text('Fixed 2 likely slips'), findsOneWidget);
    });
  });

  testWidgets('Edit returns to the field with the swapped text preserved',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byType(TextField), 'ሰላም');
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    tapFlaggedLetter(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ሠ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'ሠላም');
  });
}
