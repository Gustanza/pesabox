import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pesa_box_app/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PesaBoxApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
