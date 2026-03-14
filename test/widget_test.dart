import 'package:Project_SPA/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Myapp renders provided initial page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Myapp(initialPage: Scaffold(body: Text('Smoke Test'))),
    );

    expect(find.text('Smoke Test'), findsOneWidget);
  });
}
