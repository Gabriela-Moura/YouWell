// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youwell/main.dart';

void main() {
  testWidgets('home screen shows one login action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('YouWell'), findsOneWidget);
    expect(find.text('Saúde e bem-estar corporativo'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
