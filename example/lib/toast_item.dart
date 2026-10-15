import 'package:animated_toast_list/animated_toast_list.dart';
import 'package:flutter/material.dart';
import 'package:sample/toast_model.dart';
import 'package:sample/toast_type.dart';

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
