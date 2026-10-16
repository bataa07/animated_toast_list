import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/main.dart';

void main() {
  testWidgets('shows and closes a toast', (tester) async {
    await tester.pumpWidget(const SampleApp());

    await tester.tap(find.text('Show Success Toast'));
    await tester.pumpAndSettle();
    expect(find.text('Saved successfully'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Saved successfully'), findsNothing);
  });

  testWidgets('hides toasts after the timeout', (tester) async {
    await tester.pumpWidget(const SampleApp());

    await tester.tap(find.text('Show Info Toast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Failed Toast'));
    await tester.pumpAndSettle();
    expect(find.text('A new version is available'), findsOneWidget);
    expect(find.text('Connection failed'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('A new version is available'), findsNothing);
    expect(find.text('Connection failed'), findsNothing);
  });

  testWidgets('keeps a persistent toast until it is closed', (tester) async {
    await tester.pumpWidget(const SampleApp());

    await tester.tap(find.text('Show Persistent Toast'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('Stays until you close it'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Stays until you close it'), findsNothing);
  });

  testWidgets('keeps the toast visible while navigating', (tester) async {
    await tester.pumpWidget(const SampleApp());

    await tester.tap(find.text('Show toast and Navigate'));
    await tester.pumpAndSettle();
    expect(find.text('Second screen'), findsOneWidget);
    expect(find.byType(ListTile).hitTestable(), findsOneWidget);

    await tester.tap(find.text('Go back!'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
  });
}
