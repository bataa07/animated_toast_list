import 'dart:math';

import 'package:animated_toast_list/animated_toast_list.dart';
import 'package:flutter/material.dart';
import 'package:sample/second_screen.dart';
import 'package:sample/toast_model.dart';
import 'package:sample/toast_type.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

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
                TextButton(
                  onPressed: () => context.showToast(
                      MyToastModel(ToastType.success.name, ToastType.success)),
                  child: const Text('Show Success Toast'),
                ),
                TextButton(
                  onPressed: () => context.showToast(
                      MyToastModel(ToastType.warning.name, ToastType.warning)),
                  child: const Text('Show Warning Toast'),
                ),
                TextButton(
                  onPressed: () => context.showToast(
                      MyToastModel(ToastType.info.name, ToastType.info)),
                  child: const Text('Show Info Toast'),
                ),
                TextButton(
                  onPressed: () => context.showToast(
                      MyToastModel(ToastType.failed.name, ToastType.failed)),
                  child: const Text('Show Failed Toast'),
                ),
                TextButton(
                  onPressed: () => context.showToast(
                    MyToastModel('Custom timer', ToastType.info),
                    duration: const Duration(seconds: 10),
                  ),
                  child: const Text('Show Toast with custom timer (10 sec)'),
                ),
              ],
            ),
            Tooltip(
              message: 'Show toast overlay',
              child: TextButton(
                onPressed: () => _navigate(context),
                child: const Text('Show toast and Navigate'),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
    context
        .showToast(MyToastModel('${Random().nextInt(100)}', ToastType.success));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecondScreen()),
    );
  }
}
