import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ZenToDo запускается', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Text('ZenToDo'))));
    expect(find.text('ZenToDo'), findsOneWidget);
  });
}
