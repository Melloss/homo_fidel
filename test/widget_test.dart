import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/main.dart';

void main() {
  testWidgets('app shell boots', (tester) async {
    await tester.pumpWidget(const HomofidelApp());
    expect(find.text('HomoFidel'), findsOneWidget);
  });
}
