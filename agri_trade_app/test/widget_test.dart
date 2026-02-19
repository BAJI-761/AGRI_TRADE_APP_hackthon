import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agri_trade_app/main.dart';

void main() {
  testWidgets('Login screen loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen loads (check for a text field or title).
    expect(find.byType(TextField),
        findsWidgets); // Expects name and address fields
    expect(find.text('Login'), findsOneWidget); // Expects login button or title
  });
}
