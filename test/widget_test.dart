import 'package:flutter_test/flutter_test.dart';
import 'package:next_doc/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const NextDocApp());
    expect(find.text('NextDoc'), findsOneWidget);
  });
}
