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
  bool useSafeArea = true,
  Key? appKey,
}) {
  return ToastListOverlay<String>(
    itemBuilder: itemBuilder,
    position: position,
    reverse: reverse,
    limit: limit,
    timeoutDuration: timeoutDuration,
    useSafeArea: useSafeArea,
    child: MaterialApp(
      key: appKey,
      home: const Scaffold(body: SizedBox.expand(key: _homeKey)),
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
    expect(find.textContaining('toast '), findsNothing);
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

  // https://github.com/bataa07/animated_toast_list/issues/9
  testWidgets('shows every toast shown from a GestureDetector', (
    tester,
  ) async {
    var count = 0;
    await tester.pumpWidget(
      ToastListOverlay<String>(
        itemBuilder: _buildToast,
        child: MaterialApp(
          home: Builder(
            builder: (context) => GestureDetector(
              // Unlike a button, a GestureDetector does not animate when it is
              // tapped, so no other frame is scheduled.
              onTap: () => context.showToast('${++count}'),
              child: const ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();
    }

    expect(_toast('1'), findsOneWidget);
    expect(_toast('2'), findsOneWidget);
    expect(_toast('3'), findsOneWidget);

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
    expect(find.textContaining('toast '), findsNothing);
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
    expect(find.textContaining('toast '), findsNothing);
  });

  testWidgets('hides the last toast when frames run without microtasks', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final BuildContext context = _homeContext(tester);

    context.showToast('a');
    await tester.pumpAndSettle();

    context.hideToast('a');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The web engine runs both phases of a frame before it flushes the
    // microtasks, unlike pump().
    final Duration timestamp = Duration(
      microseconds: tester.binding.clock.now().microsecondsSinceEpoch,
    );
    tester.binding
      ..handleBeginFrame(timestamp + const Duration(seconds: 1))
      ..handleDrawFrame();
    await tester.pumpAndSettle();

    expect(_toast('a'), findsNothing);
    expect(find.textContaining('toast '), findsNothing);
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

  group('useSafeArea', () {
    // The test view is 800x600 logical pixels.
    void setViewPadding(WidgetTester tester) {
      tester.view.padding = FakeViewPadding(
        top: 50 * tester.view.devicePixelRatio,
        bottom: 40 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.reset);
    }

    Future<Rect> showToastAt(
      WidgetTester tester, {
      required Alignment position,
      required bool useSafeArea,
    }) async {
      await tester.pumpWidget(
        _app(position: position, useSafeArea: useSafeArea),
      );
      _homeContext(tester).showToast('a');
      await tester.pumpAndSettle();
      final Rect rect = tester.getRect(find.byType(SizeTransition));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      return rect;
    }

    testWidgets('keeps the toasts out of the padding by default', (
      tester,
    ) async {
      setViewPadding(tester);

      final Rect top = await showToastAt(
        tester,
        position: Alignment.topCenter,
        useSafeArea: true,
      );
      expect(top.top, 50);

      final Rect bottom = await showToastAt(
        tester,
        position: Alignment.bottomCenter,
        useSafeArea: true,
      );
      expect(bottom.bottom, 600 - 40);
    });

    testWidgets('displays the toasts edge to edge when false', (
      tester,
    ) async {
      setViewPadding(tester);

      final Rect top = await showToastAt(
        tester,
        position: Alignment.topCenter,
        useSafeArea: false,
      );
      expect(top.top, 0);

      final Rect bottom = await showToastAt(
        tester,
        position: Alignment.bottomCenter,
        useSafeArea: false,
      );
      expect(bottom.bottom, 600);
    });
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
    expect(find.textContaining('toast '), findsNothing);

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
    expect(find.textContaining('toast '), findsNothing);
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

  testWidgets('hides a toast that is not displayed yet', (tester) async {
    await tester.pumpWidget(_app());
    final BuildContext context = _homeContext(tester);

    // The first toast waits for the list to be built.
    context
      ..showToast('a', persist: true)
      ..hideToast('a');
    await tester.pumpAndSettle();
    expect(_toast('a'), findsNothing);
    expect(find.textContaining('toast '), findsNothing);
  });

  testWidgets('hides toasts that were hidden before they were built', (
    tester,
  ) async {
    await tester.pumpWidget(_app(limit: 1));
    final BuildContext context = _homeContext(tester);

    context.showToast('a');
    await tester.pumpAndSettle();
    // Hidden in the frame it is inserted, so its exit builder is never called.
    context.showToast('b').hide();
    // Evicted by the limit in the frame it is inserted.
    context
      ..showToast('c')
      ..showToast('d');
    await tester.pumpAndSettle();
    expect(_toast('d'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.textContaining('toast '), findsNothing);
  });

  testWidgets('hides toasts below the screen', (
    tester,
  ) async {
    Widget tall(BuildContext c, String item, int i, Animation<double> a) =>
        SizeTransition(
          sizeFactor: a,
          child: SizedBox(height: 200, child: Text('toast $item')),
        );
    await tester.pumpWidget(_app(itemBuilder: tall, limit: 10));
    final BuildContext context = _homeContext(tester);

    final List<ToastHandle> toasts = <ToastHandle>[];
    for (var i = 0; i < 7; i++) {
      toasts.add(context.showToast('$i', persist: true));
      await tester.pumpAndSettle();
    }
    // The oldest toast is below the screen, so its exit builder is not called.
    toasts.first.hide();
    await tester.pumpAndSettle();
    for (final ToastHandle toast in toasts) {
      toast.hide();
    }
    await tester.pumpAndSettle();
    expect(find.textContaining('toast '), findsNothing);
  });

  testWidgets('hides the extra toasts when the limit is lowered', (
    tester,
  ) async {
    await tester.pumpWidget(_app(limit: 3));
    final BuildContext context = _homeContext(tester);
    for (final String item in <String>['a', 'b', 'c']) {
      context.showToast(item);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(_app(limit: 1));
    await tester.pumpAndSettle();
    expect(_toast('a'), findsNothing);
    expect(_toast('b'), findsNothing);
    expect(_toast('c'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('shows toasts after the Overlay was recreated', (tester) async {
    await tester.pumpWidget(_app(appKey: const ValueKey<int>(1)));
    final ToastHandle a = _homeContext(tester).showToast('a', persist: true);
    await tester.pumpAndSettle();

    // For example, the app is rebuilt with a new key after a locale change.
    await tester.pumpWidget(_app(appKey: const ValueKey<int>(2)));
    await tester.pumpAndSettle();
    expect(_toast('a').hitTestable(), findsOneWidget);
    expect(a.isShowing, isTrue);

    _homeContext(tester).showToast('b');
    await tester.pumpAndSettle();
    expect(_toast('b').hitTestable(), findsOneWidget);

    a.hide();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.textContaining('toast '), findsNothing);
  });

  testWidgets('shows a toast from initState', (tester) async {
    await tester.pumpWidget(
      ToastListOverlay<String>(
        itemBuilder: _buildToast,
        child: MaterialApp(
          home: _InitStateToast(onInit: (context) => context.showToast('a')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_toast('a'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  group('with nested Navigators', () {
    // Like a ShellRoute of go_router: the shell has its own Navigator, and a
    // full screen route is pushed on the root Navigator.
    testWidgets('shows a toast from a root route after one from the shell', (
      tester,
    ) async {
      final GlobalKey<NavigatorState> root = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ToastListOverlay<String>(
          itemBuilder: _buildToast,
          child: MaterialApp(
            navigatorKey: root,
            home: Scaffold(
              body: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => const SizedBox.expand(key: Key('shell')),
                ),
              ),
            ),
          ),
        ),
      );

      tester.element(find.byKey(const Key('shell'))).showToast('a');
      await tester.pumpAndSettle();
      expect(_toast('a').hitTestable(), findsOneWidget);

      root.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const SizedBox.expand(key: Key('details')),
        ),
      );
      await tester.pumpAndSettle();
      tester.element(find.byKey(const Key('details'))).showToast('b');
      await tester.pumpAndSettle();
      expect(_toast('a').hitTestable(), findsOneWidget);
      expect(_toast('b').hitTestable(), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('shows a toast from a second tab', (tester) async {
      final ValueNotifier<int> tab = ValueNotifier<int>(0);
      addTearDown(tab.dispose);
      Widget tabNavigator(int index) => Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => SizedBox.expand(key: ValueKey<int>(index)),
            ),
          );
      await tester.pumpWidget(
        ToastListOverlay<String>(
          itemBuilder: _buildToast,
          child: MaterialApp(
            home: ValueListenableBuilder<int>(
              valueListenable: tab,
              builder: (context, index, _) => IndexedStack(
                index: index,
                children: <Widget>[tabNavigator(0), tabNavigator(1)],
              ),
            ),
          ),
        ),
      );

      tester.element(find.byKey(const ValueKey<int>(0))).showToast('a');
      await tester.pumpAndSettle();
      tab.value = 1;
      await tester.pumpAndSettle();
      tester.element(find.byKey(const ValueKey<int>(1))).showToast('b');
      await tester.pumpAndSettle();
      expect(_toast('a').hitTestable(), findsOneWidget);
      expect(_toast('b').hitTestable(), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('shows a toast from a context above the Navigator', () {
    testWidgets('of a navigator key', (tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ToastListOverlay<String>(
          itemBuilder: _buildToast,
          child: MaterialApp(
            navigatorKey: navigator,
            home: const SizedBox.expand(),
          ),
        ),
      );

      navigator.currentContext!.showToast('a');
      await tester.pumpAndSettle();
      expect(_toast('a'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('of MaterialApp.builder', (tester) async {
      late BuildContext builderContext;
      await tester.pumpWidget(
        ToastListOverlay<String>(
          itemBuilder: _buildToast,
          child: MaterialApp(
            builder: (context, child) {
              builderContext = context;
              return child!;
            },
            home: const SizedBox.expand(),
          ),
        ),
      );

      builderContext.showToast('a');
      await tester.pumpAndSettle();
      expect(_toast('a'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('hides a toast in dispose', (tester) async {
    await tester.pumpWidget(_app());
    final NavigatorState navigator = tester.state(find.byType(Navigator));

    // Shows a persistent toast in initState and hides it in dispose.
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const _UploadScreen()),
    );
    await tester.pumpAndSettle();
    expect(_toast('uploading'), findsOneWidget);

    navigator.pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_toast('uploading'), findsNothing);
  });

  testWidgets('hides a toast in initState', (tester) async {
    await tester.pumpWidget(_app());
    _homeContext(tester).showToast('a', persist: true);
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator)).push(
          MaterialPageRoute<void>(
            builder: (_) => _InitStateToast(
              onInit: (context) => context.hideToast('a'),
            ),
          ),
        );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_toast('a'), findsNothing);
  });

  testWidgets('reports a missing Overlay when shown during build', (
    tester,
  ) async {
    late ToastHandle toast;
    await tester.pumpWidget(
      ToastListOverlay<String>(
        itemBuilder: _buildToast,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: _InitStateToast(
            onInit: (context) => toast = context.showToast('a'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.takeException(),
      isA<FlutterError>().having(
        (error) => error.message,
        'message',
        contains('No Overlay widget found.'),
      ),
    );
    expect(toast.isShowing, isFalse);
  });

  testWidgets('does not report a missing Overlay when no toast is shown', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    _homeContext(tester).showToast('a', persist: true);
    await tester.pumpAndSettle();

    // For example, a loading screen without an Overlay replaces the app.
    await tester.pumpWidget(
      const ToastListOverlay<String>(
        itemBuilder: _buildToast,
        child: ColoredBox(color: Color(0xFF000000)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not show again a toast hidden without an Overlay', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const _UploadScreen()),
    );
    await tester.pumpAndSettle();
    expect(_toast('uploading'), findsOneWidget);

    // The screen hides its toast in dispose while the app is replaced.
    await tester.pumpWidget(
      const ToastListOverlay<String>(
        itemBuilder: _buildToast,
        child: ColoredBox(color: Color(0xFF000000)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_app());
    _homeContext(tester).showToast('b');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_toast('b'), findsOneWidget);
    expect(_toast('uploading'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  group('when it wraps a screen', () {
    Widget tabNavigator(int index) => Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => SizedBox.expand(key: ValueKey<int>(index)),
          ),
        );

    testWidgets('shows a toast from the app bar above tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ToastListOverlay<String>(
            itemBuilder: _buildToast,
            child: Scaffold(
              appBar: AppBar(title: const Text('title')),
              body: IndexedStack(
                index: 1,
                children: <Widget>[tabNavigator(0), tabNavigator(1)],
              ),
            ),
          ),
        ),
      );

      tester.element(find.text('title')).showToast('a');
      await tester.pumpAndSettle();
      expect(_toast('a').hitTestable(), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('shows a toast across the screen with a side panel', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ToastListOverlay<String>(
            itemBuilder: _buildToast,
            child: Scaffold(
              appBar: AppBar(title: const Text('title')),
              body: Row(
                children: <Widget>[
                  const Expanded(child: SizedBox.expand()),
                  SizedBox(width: 200, child: tabNavigator(0)),
                ],
              ),
            ),
          ),
        ),
      );

      tester.element(find.text('title')).showToast('a');
      await tester.pumpAndSettle();
      // Centered on the 800 pixels wide test view, not in the panel.
      expect(tester.getCenter(find.byType(SizeTransition)).dx, 400);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('shows toasts from several tabs', (tester) async {
      final ValueNotifier<int> tab = ValueNotifier<int>(0);
      addTearDown(tab.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ToastListOverlay<String>(
            itemBuilder: _buildToast,
            child: ValueListenableBuilder<int>(
              valueListenable: tab,
              builder: (context, index, _) => IndexedStack(
                index: index,
                children: <Widget>[tabNavigator(0), tabNavigator(1)],
              ),
            ),
          ),
        ),
      );

      tester.element(find.byKey(const ValueKey<int>(0))).showToast('a');
      await tester.pumpAndSettle();
      tab.value = 1;
      await tester.pumpAndSettle();
      tester.element(find.byKey(const ValueKey<int>(1))).showToast('b');
      await tester.pumpAndSettle();
      expect(_toast('a').hitTestable(), findsOneWidget);
      expect(_toast('b').hitTestable(), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  // The README of 1.0.2 suggested wrapping any widget, such as a screen.
  testWidgets('works when it wraps a screen of a Navigator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _ScreenWithToasts()));

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    // Rebuilds the ToastListOverlay while a toast is displayed.
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_toast('1'), findsOneWidget);
    expect(_toast('2'), findsOneWidget);

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

class _InitStateToast extends StatefulWidget {
  const _InitStateToast({required this.onInit});

  final void Function(BuildContext context) onInit;

  @override
  State<_InitStateToast> createState() => _InitStateToastState();
}

class _InitStateToastState extends State<_InitStateToast> {
  @override
  void initState() {
    super.initState();
    widget.onInit(context);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _ScreenWithToasts extends StatefulWidget {
  const _ScreenWithToasts();

  @override
  State<_ScreenWithToasts> createState() => _ScreenWithToastsState();
}

class _ScreenWithToastsState extends State<_ScreenWithToasts> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return ToastListOverlay<String>(
      itemBuilder: _buildToast,
      child: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              setState(() => _count++);
              context.showToast('$_count');
            },
            child: const Text('show'),
          ),
        ),
      ),
    );
  }
}

/// Shows a persistent toast while it is displayed.
class _UploadScreen extends StatefulWidget {
  const _UploadScreen();

  @override
  State<_UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<_UploadScreen> {
  late final ToastHandle _toast;

  @override
  void initState() {
    super.initState();
    _toast = context.showToast('uploading', persist: true);
  }

  @override
  void dispose() {
    _toast.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
