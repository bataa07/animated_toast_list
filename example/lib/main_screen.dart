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
      backgroundColor: Colors.redAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Hello World!'),
            Tooltip(
              message: 'Show toast overlay',
              child: TextButton(
                onPressed: () {
                  context.showToast(MyToastModel(
                      '${Random().nextInt(100)}', ToastType.success));

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SecondScreen()),
                  );
                },
                child: const Text('Show toast and Navigate'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
