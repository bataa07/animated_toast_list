import 'package:animated_toast_list/animated_toast_list.dart';
import 'package:flutter/material.dart';
import 'package:sample/main_screen.dart';
import 'package:sample/toast_item.dart';
import 'package:sample/toast_model.dart';

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
