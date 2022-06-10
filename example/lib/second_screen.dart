import 'dart:math';

import 'package:animated_toast_list/animated_toast_list.dart';
import 'package:flutter/material.dart';
import 'package:sample/toast_model.dart';
import 'package:sample/toast_type.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({Key? key}) : super(key: key);

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
                MyToastModel('${Random().nextInt(100)}', ToastType.failed));
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}
