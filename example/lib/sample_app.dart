import 'package:animated_toast_list/animated_toast_list.dart';
import 'package:flutter/material.dart';
import 'package:sample/card_item.dart';
import 'package:sample/main_screen.dart';
import 'package:sample/toast_model.dart';

class SampleApp extends StatelessWidget {
  const SampleApp({Key? key}) : super(key: key);

  Widget _buildItem(BuildContext context, MyToastModel item, int index,
      Animation<double> animation) {
    return CardItem(
      animation: animation,
      item: item,
      selected: false,
      onTap: () {
        ToastListOverlay.of<MyToastModel>(context).removeItem(item,
            (context, animation) {
          return _buildItem(context, item, index, animation);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ToastListOverlay<MyToastModel>(
      // position: Alignment.bottomCenter,
      // reverse: true,
      // limit: 1,
      itemBuilder: (context, item, index, animation) {
        return _buildItem(context, item, index, animation);
      },
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
