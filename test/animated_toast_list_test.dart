import 'package:animated_toast_list/animated_toast_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _homeKey = Key('home');

Widget _buildToast(
  BuildContext context,
  String item,
  int index,
  Animation<double> animation,
) {
  return SizeTransition(
    sizeFactor: animation,
    child: SizedBox(height: 50, child: Text('toast $item')),
  );
}

Widget _app({
  ToastListItemBuilder<String> itemBuilder = _buildToast,
  Alignment position = Alignment.topCenter,
  bool reverse = false,
  int limit = 5,
  Duration timeoutDuration = const Duration(seconds: 5),
}) {
  return ToastListOverlay<String>(
    itemBuilder: itemBuilder,
    position: position,
    reverse: reverse,
    limit: limit,
    timeoutDuration: timeoutDuration,
    child: const MaterialApp(
      home: Scaffold(body: SizedBox.expand(key: _homeKey)),
    ),
  );
}

BuildContext _homeContext(WidgetTester tester) => tester.element(
      find.byKey(_homeKey),
    );

Finder _toast(String item) => find.text('toast $item');

void main() {
  testWidgets('shows a toast and hides it after the timeout', (tester) async {
    await tester.pumpWidget(_app());

    _homeContext(tester).showToast('a');
    await tester.pumpAndSettle();
    expect(_toast('a'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(_toast('a'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(_toast('a'), findsNothing);
    expect(find.byType(AnimatedList), findsNothing);
  });

  testWidgets('plays the entrance animation', (tester) async {
    await tester.pumpWidget(_app());

    _homeContext(tester).showToast('a');
    // Builds the overlay, then inserts the toast and starts the animation.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final double height = tester.getSize(find.byType(SizeTransition)).height;
    expect(height, greaterThan(0));
    expect(height, lessThan(50));

    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(SizeTransition)).height, 50);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('shows a new toast without waiting for another frame', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final BuildContext context = _homeContext(tester);

    context.showToast('a');
    await tester.pumpAndSettle();

    context.showToast('b');
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpAndSettle();
    expect(_toast('b'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('displays the newest toast first', (tester) async {
    await tester.pumpWidget(_app());
    final BuildContext context = _homeContext(tester);

    // Both toasts are shown before the overlay is built.
    context
      ..showToast('a')
      ..showToast('b');
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(_toast('b')).dy,
      lessThan(tester.getTopLeft(_toast('a')).dy),
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('displays the newest toast last when reverse is true', (
    tester,
  ) async {
    await tester.pumpWidget(_app(reverse: true));
    final BuildContext context = _homeContext(tester);

    context.showToast('a');
    await tester.pumpAndSettle();
    context.showToast('b');
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(_toast('b')).dy,
      greaterThan(tester.getTopLeft(_toast('a')).dy),
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('hides the oldest toast when the limit is reached', (
    tester,
  ) async {
    await tester.pumpWidget(_app(limit: 2));
    final BuildContext context = _homeContext(tester);

    for (final String item in <String>['a', 'b', 'c']) {
      context.showToast(item);
      await tester.pumpAndSettle();
    }

    expect(_toast('a'), findsNothing);
    expect(_toast('b'), findsOneWidget);
    expect(_toast('c'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('hideToast uses the itemBuilder when no builder is given', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final BuildContext context = _homeContext(tester);

    context.showToast('a');
    await tester.pumpAndSettle();

    context.hideToast('a');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(_toast('a'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(_toast('a'), findsNothing);
    expect(find.byType(AnimatedList), findsNothing);
  });

  testWidgets('hideToast uses the given builder', (tester) async {
    await tester.pumpWidget(_app());
    final BuildContext context = _homeContext(tester);

    context.showToast('a');
    await tester.pumpAndSettle();

    context.hideToast<String>(
      'a',
      (context, animation) => const Text('removing a'),
    );
    await tester.pump();
    expect(find.text('removing a'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('removing a'), findsNothing);
  });

  testWidgets('hideToast ignores toasts that are not displayed', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final BuildContext context = _homeContext(tester);

    context.showToast('a');
    await tester.pumpAndSettle();

    context.hideToast('b');
    await tester.pumpAndSettle();
    expect(_toast('a'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('shows a toast right after the last one was hidden', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final BuildContext context = _homeContext(tester);

    context.showToast('a');
    await tester.pumpAndSettle();

    context.hideToast('a');
    await tester.pump();
    // Finishes the exit animation, which removes the overlay entry.
    await tester.pump(const Duration(milliseconds: 300));

    context.showToast('b');
    await tester.pumpAndSettle();
    expect(_toast('a'), findsNothing);
    expect(_toast('b'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedList), findsNothing);
  });

  testWidgets('keeps the toast above a newly pushed route', (tester) async {
    await tester.pumpWidget(_app());
    final BuildContext context = _homeContext(tester);

    context.showToast('a');
    await tester.pumpAndSettle();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const Scaffold(body: Text('second')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
    expect(_toast('a').hitTestable(), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('applies updated properties to displayed toasts', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    _homeContext(tester).showToast('a');
    await tester.pumpAndSettle();
    expect(tester.getCenter(_toast('a')).dy, lessThan(300));

    await tester.pumpWidget(_app(position: Alignment.bottomCenter));
    expect(tester.getCenter(_toast('a')).dy, greaterThan(300));

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('cancels the timers when it is disposed', (tester) async {
    await tester.pumpWidget(_app());

    _homeContext(tester).showToast('a');
    await tester.pumpAndSettle();

    // The test fails if a timer is still pending at the end.
    await tester.pumpWidget(const SizedBox());
    expect(_toast('a'), findsNothing);
  });

  testWidgets('throws a helpful error without a ToastListOverlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SizedBox.expand(key: _homeKey)),
    );

    expect(
      () => _homeContext(tester).showToast('a'),
      throwsA(
        isA<FlutterError>().having(
          (error) => error.message,
          'message',
          contains('No ToastListOverlay widget found.'),
        ),
      ),
    );
  });

  testWidgets('throws when no ToastListOverlay accepts the type', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(
      () => _homeContext(tester).showToast(1),
      throwsA(isA<FlutterError>()),
    );
  });

  testWidgets('shows toasts whose type is a subtype of the overlay type', (
    tester,
  ) async {
    await tester.pumpWidget(
      ToastListOverlay<_Toast>(
        itemBuilder: (context, item, index, animation) =>
            Text('toast ${item.message}'),
        child: const MaterialApp(home: SizedBox.expand(key: _homeKey)),
      ),
    );
    final BuildContext context = _homeContext(tester);

    context.showToast(_SuccessToast('a'));
    await tester.pumpAndSettle();
    expect(_toast('a'), findsOneWidget);

    final _FailedToast failed = _FailedToast('b');
    context.showToast(failed);
    await tester.pumpAndSettle();
    expect(_toast('b'), findsOneWidget);

    context.hideToast(failed);
    await tester.pumpAndSettle();
    expect(_toast('b'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('uses the closest ToastListOverlay that accepts the type', (
    tester,
  ) async {
    await tester.pumpWidget(
      ToastListOverlay<String>(
        itemBuilder: (context, item, index, animation) => Text('string $item'),
        child: ToastListOverlay<int>(
          itemBuilder: (context, item, index, animation) => Text('int $item'),
          child: const MaterialApp(home: SizedBox.expand(key: _homeKey)),
        ),
      ),
    );
    final BuildContext context = _homeContext(tester);

    context
      ..showToast('a')
      ..showToast(1);
    await tester.pumpAndSettle();
    expect(find.text('string a'), findsOneWidget);
    expect(find.text('int 1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('hides a toast after its own duration', (tester) async {
    await tester.pumpWidget(_app());

    _homeContext(tester).showToast('a', duration: const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(_toast('a'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(_toast('a'), findsNothing);
  });

  testWidgets('keeps a persistent toast until it is hidden', (tester) async {
    await tester.pumpWidget(_app());

    final ToastHandle toast = _homeContext(tester).showToast(
      'a',
      persist: true,
    );
    expect(toast.isShowing, isTrue);
    await tester.pumpAndSettle();

    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(_toast('a'), findsOneWidget);
    expect(toast.isShowing, isTrue);

    toast.hide();
    expect(toast.isShowing, isFalse);
    await tester.pumpAndSettle();
    expect(_toast('a'), findsNothing);
    expect(find.byType(AnimatedList), findsNothing);

    // Hiding it again does nothing.
    toast.hide();
    await tester.pumpAndSettle();
  });

  testWidgets('hides the toast of a handle among equal toasts', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final BuildContext context = _homeContext(tester);

    final ToastHandle first = context.showToast('a', persist: true);
    await tester.pumpAndSettle();
    final ToastHandle second = context.showToast('a', persist: true);
    await tester.pumpAndSettle();
    expect(_toast('a'), findsNWidgets(2));

    first.hide();
    await tester.pumpAndSettle();
    expect(_toast('a'), findsOneWidget);
    expect(first.isShowing, isFalse);
    expect(second.isShowing, isTrue);

    second.hide();
    await tester.pumpAndSettle();
    expect(_toast('a'), findsNothing);
  });

  testWidgets('does not show a toast hidden before it was displayed', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    _homeContext(tester).showToast('a').hide();
    await tester.pumpAndSettle();
    expect(_toast('a'), findsNothing);
    expect(find.byType(AnimatedList), findsNothing);
  });

  testWidgets('hides a persistent toast when the limit is reached', (
    tester,
  ) async {
    await tester.pumpWidget(_app(limit: 1));
    final BuildContext context = _homeContext(tester);

    final ToastHandle toast = context.showToast('a', persist: true);
    await tester.pumpAndSettle();
    context.showToast('b');
    await tester.pumpAndSettle();

    expect(_toast('a'), findsNothing);
    expect(toast.isShowing, isFalse);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('asserts that limit is greater than 0', (tester) async {
    expect(() => _app(limit: 0), throwsAssertionError);
  });
}

sealed class _Toast {
  _Toast(this.message);

  final String message;
}

class _SuccessToast extends _Toast {
  _SuccessToast(super.message);
}

class _FailedToast extends _Toast {
  _FailedToast(super.message);
}
