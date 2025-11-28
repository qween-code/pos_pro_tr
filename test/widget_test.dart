// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_pro_tr/app.dart';

void main() {
  testWidgets('POS Pro uygulama testi', (WidgetTester tester) async {
    // Uygulamayı başlat
    await tester.pumpWidget(const PosProApp());

    // Uygulamanın başarıyla yüklendiğini kontrol et
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
