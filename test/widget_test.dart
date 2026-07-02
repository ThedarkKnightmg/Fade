// Basic smoke test: the app builds without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:barber_app/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const BarberApp());
    expect(find.byType(BarberApp), findsOneWidget);
  });
}
