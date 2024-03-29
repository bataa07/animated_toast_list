import 'package:animated_toast_list/src/toast_list_overlay.dart';
import 'package:flutter/widgets.dart';

extension ToastListExtension on BuildContext {
  void showToast<T>(T text, {Duration? duration}) {
    ToastListOverlay.of<T>(this).show(this, text, duration: duration);
  }

  void hideToast<T>(
    T item,
    Widget Function(BuildContext, Animation<double>) builder,
  ) {
    ToastListOverlay.of<T>(this).removeItem(item, builder);
  }
}
