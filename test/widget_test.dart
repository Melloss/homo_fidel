import 'package:flutter_test/flutter_test.dart';
import 'package:homofidel/injection_container.dart' as di;
import 'package:homofidel/main.dart';

void main() {
  setUpAll(di.init);

  testWidgets('app shell boots into the checker screen', (tester) async {
    await tester.pumpWidget(const HomofidelApp());
    expect(find.text('Homofidäl'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
  });
}
