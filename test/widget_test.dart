import 'package:flutter_test/flutter_test.dart';

import 'package:zakzouka/main.dart';

void main() {
  testWidgets('Splash shows app title', (WidgetTester tester) async {
    await tester.pumpWidget(const ScooterApp());
    expect(find.text('Smart Scooter'), findsOneWidget);
  });
}
