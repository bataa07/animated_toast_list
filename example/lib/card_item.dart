import 'package:flutter/material.dart';
import 'package:sample/toast_model.dart';
import 'package:sample/toast_type.dart';

class CardItem extends StatelessWidget {
  const CardItem({
    Key? key,
    this.onTap,
    this.selected = false,
    required this.animation,
    required this.item,
  }) : super(key: key);

  final Animation<double> animation;
  final VoidCallback? onTap;
  final MyToastModel item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.headline4!;
    if (selected) {
      textStyle = textStyle.copyWith(color: Colors.lightGreenAccent[400]);
    }
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizeTransition(
        sizeFactor: animation,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 80.0,
            child: Card(
              color: item.type == ToastType.success ? Colors.green : Colors.red,
              child: Center(
                child: Text('Item ${item.message}', style: textStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
