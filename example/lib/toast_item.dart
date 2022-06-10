import 'package:flutter/material.dart';
import 'package:sample/toast_model.dart';
import 'package:sample/toast_type.dart';

class ToastItem extends StatelessWidget {
  const ToastItem({
    Key? key,
    this.onTap,
    required this.animation,
    required this.item,
  }) : super(key: key);

  final Animation<double> animation;
  final VoidCallback? onTap;
  final MyToastModel item;

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle =
        Theme.of(context).textTheme.headline6!.copyWith(color: Colors.white);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          child: Container(
            decoration: BoxDecoration(
              color: _getTypeColor(item.type),
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
            ),
            child: ListTile(
              title: Text('Item ${item.message}', style: textStyle),
              trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onTap?.call()),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF3DD89B);
      case ToastType.warning:
        return const Color(0xFFFFD873);
      case ToastType.info:
        return const Color(0xFF17A2b8);
      case ToastType.failed:
        return const Color(0xFFFF4E43);
      default:
        return const Color(0xFF3DD89B);
    }
  }
}
