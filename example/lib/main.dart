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

  static const Map<ToastType, String> _messages = {
    ToastType.success: 'Saved successfully',
    ToastType.warning: 'Your session expires soon',
    ToastType.info: 'A new version is available',
    ToastType.failed: 'Connection failed',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ToastType type in ToastType.values)
                FilledButton.tonal(
                  onPressed: () =>
                      context.showToast(MyToastModel(_messages[type]!, type)),
                  child: Text('Show ${_capitalize(type.name)} Toast'),
                ),
              FilledButton.tonal(
                // Stays until the close button is pressed.
                onPressed: () => context.showToast(
                  MyToastModel('Stays until you close it', ToastType.info),
                  persist: true,
                ),
                child: const Text('Show Persistent Toast'),
              ),
              OutlinedButton(
                onPressed: () => _navigate(context),
                child: const Text('Show toast and Navigate'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
    // The toast stays visible on the next screen.
    context.showToast(
      MyToastModel('Shown before navigating', ToastType.success),
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
        child: FilledButton(
          onPressed: () {
            Navigator.pop(context);
            context.showToast(
              MyToastModel('Shown after going back', ToastType.info),
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
    final (Color color, IconData icon) = switch (item.type) {
      ToastType.success => (const Color(0xFF2E9E6A), Icons.check_circle),
      ToastType.warning => (const Color(0xFFD9822B), Icons.warning_rounded),
      ToastType.info => (const Color(0xFF1F7FB8), Icons.info),
      ToastType.failed => (const Color(0xFFD64541), Icons.error),
    };

    // Lets screen readers announce the toast when it appears.
    return Semantics(
      liveRegion: true,
      child: FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          // The padding is inside the SizeTransition, so it shrinks with the
          // toast and leaves room for the shadow.
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Material(
              color: color,
              elevation: 4,
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              child: ListTile(
                iconColor: Colors.white,
                textColor: Colors.white,
                leading: Icon(icon),
                title: Text(item.message),
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
}
