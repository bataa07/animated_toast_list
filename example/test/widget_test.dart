import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample/main.dart';

void main() {
  testWidgets('shows and closes a toast', (tester) async {
    await tester.pumpWidget(const SampleApp());

    await tester.tap(find.text('Show Success Toast'));
    await tester.pumpAndSettle();
    expect(find.text('Item success'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Item success'), findsNothing);
  });

  testWidgets('hides toasts after the timeout', (tester) async {
    await tester.pumpWidget(const SampleApp());

    await tester.tap(find.text('Show Info Toast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Failed Toast'));
    await tester.pumpAndSettle();
    expect(find.text('Item info'), findsOneWidget);
    expect(find.text('Item failed'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Item info'), findsNothing);
    expect(find.text('Item failed'), findsNothing);
  });

  testWidgets('keeps a persistent toast until it is closed', (tester) async {
    await tester.pumpWidget(const SampleApp());

    await tester.tap(find.text('Show Persistent Toast'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('Item persistent'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Item persistent'), findsNothing);
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
