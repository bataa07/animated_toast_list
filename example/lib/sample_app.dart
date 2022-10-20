import 'package:animated_toast_list/animated_toast_list.dart';
import 'package:flutter/material.dart';
import 'package:sample/main_screen.dart';
import 'package:sample/toast_item.dart';
import 'package:sample/toast_model.dart';

class SampleApp extends StatelessWidget {
  const SampleApp({Key? key}) : super(key: key);

  Widget _buildItem(
    BuildContext context,
    MyToastModel item,
    int index,
    Animation<double> animation,
  ) {
    return ToastItem(
      animation: animation,
      item: item,
      onTap: () => context.hideToast(
        item,
        (context, animation) => _buildItem(context, item, index, animation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ToastListOverlay<MyToastModel>(
      // position: Alignment.topLeft,
      // reverse: true,
      // limit: 1,
      // timeoutDuration: const Duration(seconds: 5),
      // width: 400,
      itemBuilder: (
        BuildContext context,
        MyToastModel item,
        int index,
        Animation<double> animation,
      ) =>
          _buildItem(context, item, index, animation),
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
