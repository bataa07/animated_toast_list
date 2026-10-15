import 'package:flutter/widgets.dart';

import 'toast_list_overlay.dart';

/// Shows and hides toasts of the closest [ToastListOverlay] ancestor.
extension ToastListExtension on BuildContext {
  /// Shows [toast] in the closest [ToastListOverlay] of type [T].
  ///
  /// The toast is hidden automatically after
  /// [ToastListOverlay.timeoutDuration].
  void showToast<T>(T toast) {
    ToastListOverlay.of<T>(this).show(this, toast);
  }

  /// Hides [toast] from the closest [ToastListOverlay] of type [T].
  ///
  /// [builder] builds the toast while it animates out. If it is omitted,
  /// [ToastListOverlay.itemBuilder] is used.
  ///
  /// Does nothing if [toast] is not displayed.
  void hideToast<T>(T toast, [AnimatedRemovedItemBuilder? builder]) {
    ToastListOverlay.of<T>(this).removeItem(toast, builder);
  }
}
