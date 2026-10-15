import 'dart:math';

import 'package:animated_toast_list/animated_toast_list.dart';
import 'package:flutter/material.dart';

void main() => runApp(const SampleApp());

/// Any type can be a toast. This example uses a small model class.
class MyToastModel {
  MyToastModel(this.message, this.type);

  final String message;
  final ToastType type;
}

enum ToastType { success, warning, info, failed }

/// 1. Wrap the app with a ToastListOverlay and build your own toast widget.
class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastListOverlay<MyToastModel>(
      // position: Alignment.bottomCenter,
      // reverse: true,
      // limit: 3,
      // timeoutDuration: const Duration(seconds: 3),
      // width: 400,
      itemBuilder: (context, item, index, animation) =>
          ToastItem(animation: animation, item: item),
      child: MaterialApp(
        title: 'animated_toast_list',
        theme: ThemeData(colorSchemeSeed: Colors.blue),
        home: const MainScreen(),
      ),
    );
  }
}

/// 2. Show toasts with `context.showToast` from any widget below the
/// ToastListOverlay.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Hello World!'),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final ToastType type in ToastType.values)
                  TextButton(
                    onPressed: () =>
                        context.showToast(MyToastModel(type.name, type)),
                    child: Text('Show ${_capitalize(type.name)} Toast'),
                  ),
                TextButton(
                  // Stays until the close button is pressed.
                  onPressed: () => context.showToast(
                    MyToastModel('persistent', ToastType.info),
                    persist: true,
                  ),
                  child: const Text('Show Persistent Toast'),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _navigate(context),
              child: const Text('Show toast and Navigate'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
    // The toast stays visible on the next screen.
    context.showToast(
      MyToastModel('${Random().nextInt(100)}', ToastType.success),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecondScreen()),
    );
  }

  static String _capitalize(String text) =>
      text[0].toUpperCase() + text.substring(1);
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.showToast(
              MyToastModel('${Random().nextInt(100)}', ToastType.failed),
            );
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}

/// 3. The toast widget. Use the animation for the entrance and exit
/// transitions, and hide the toast with `context.hideToast`.
class ToastItem extends StatelessWidget {
  const ToastItem({
    super.key,
    required this.animation,
    required this.item,
  });

  final Animation<double> animation;
  final MyToastModel item;

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white);

    // Lets screen readers announce the toast when it appears.
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _getTypeColor(item.type),
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              ),
              child: ListTile(
                title: Text('Item ${item.message}', style: textStyle),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  tooltip: 'Close',
                  onPressed: () => context.hideToast(item),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(ToastType type) {
    return switch (type) {
      ToastType.success => const Color(0xFF3DD89B),
      ToastType.warning => const Color(0xFFFFD873),
      ToastType.info => const Color(0xFF17A2B8),
      ToastType.failed => const Color(0xFFFF4E43),
    };
  }
}
