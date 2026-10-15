import 'package:flutter/widgets.dart';

import 'toast_list_overlay.dart';

/// Shows and hides toasts of the closest [ToastListOverlay] ancestor.
extension ToastListExtension on BuildContext {
  /// Shows [toast] in the closest [ToastListOverlay] that can display toasts
  /// of type [T].
  ///
  /// The toast is hidden after [duration], or after
  /// [ToastListOverlay.timeoutDuration] if [duration] is null. If [persist]
  /// is true, the toast stays until it is hidden with [hideToast] or the
  /// returned [ToastHandle], or until it is the oldest toast when
  /// [ToastListOverlay.limit] is reached.
  ///
  /// It can be called with any context below the [ToastListOverlay], also
  /// in [State.initState] and with the context of a navigator key.
  ToastHandle showToast<T>(
    T toast, {
    Duration? duration,
    bool persist = false,
  }) {
    return ToastListOverlay.of<T>(this).show(
      this,
      toast,
      duration: duration,
      persist: persist,
    );
  }

  /// Hides [toast] from the closest [ToastListOverlay] that can display
  /// toasts of type [T].
  ///
  /// [builder] builds the toast while it animates out. If it is omitted,
  /// [ToastListOverlay.itemBuilder] is used.
  ///
  /// If several displayed toasts are equal to [toast], the newest one is
  /// hidden. Use the [ToastHandle] returned by [showToast] to hide a specific
  /// toast. Does nothing if [toast] is not displayed.
  void hideToast<T>(T toast, [AnimatedRemovedItemBuilder? builder]) {
    ToastListOverlay.of<T>(this).removeItem(toast, builder);
  }
}
