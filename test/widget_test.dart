// Basic Flutter widget test for the Plant Disease Classifier app.

import 'package:flutter_test/flutter_test.dart';

import 'package:plant_disease_classifier/main.dart';

void main() {
  testWidgets('App loads and shows home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FarmApp());

    // Verify that the home screen loads with expected content
    expect(find.text('Tap to Scan Now!'), findsOneWidget);
  });
}
