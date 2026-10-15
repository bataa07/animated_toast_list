import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'debug.dart';

/// Signature for a function that builds the widget of a single toast.
///
/// [item] is the value that was passed to [ToastListExtension.showToast],
/// [index] is the position of the toast in the list and [animation] drives
/// the entrance and exit transitions of the toast.
typedef ToastListItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
  Animation<double> animation,
);

/// Displays an animated list of toasts above [child].
///
/// Place a [ToastListOverlay] above your [MaterialApp] (or any other widget
/// that provides an [Overlay], such as [WidgetsApp] or [Navigator]) and call
/// [ToastListExtension.showToast] from any [BuildContext] below it:
///
/// ```dart
/// ToastListOverlay<MyToastModel>(
///   itemBuilder: (context, item, index, animation) => MyToast(
///     item: item,
///     animation: animation,
///   ),
///   child: MaterialApp(home: const HomeScreen()),
/// );
///
/// // Somewhere below the MaterialApp:
/// context.showToast(MyToastModel('Saved!'));
/// ```
///
/// The type argument [T] is the type of the toast items. It has to match the
/// type used with [ToastListExtension.showToast] and
/// [ToastListExtension.hideToast].
class ToastListOverlay<T> extends StatefulWidget {
  /// Creates a widget that displays toasts of type [T] above [child].
  const ToastListOverlay({
    super.key,
    required this.child,
    required this.itemBuilder,
    this.timeoutDuration = const Duration(seconds: 5),
    this.position = Alignment.topCenter,
    this.reverse = false,
    this.limit = 5,
    this.width = 375,
  }) : assert(limit > 0, 'limit must be greater than 0');

  /// The widget below this widget in the tree.
  final Widget child;

  /// How long a toast stays visible before it is hidden automatically.
  final Duration timeoutDuration;

  /// Where the toasts are displayed on the screen.
  final Alignment position;

  /// Whether the newest toast is displayed at the bottom of the list instead
  /// of the top.
  final bool reverse;

  /// The maximum number of toasts displayed at the same time.
  ///
  /// When a new toast is shown and the limit is reached, the oldest toast is
  /// hidden.
  final int limit;

  /// Builds the widget of each toast.
  final ToastListItemBuilder<T> itemBuilder;

  /// The maximum width of the toasts.
  final double width;

  /// Returns the state of the closest [ToastListOverlay] ancestor of
  /// [context].
  ///
  /// Prefer [ToastListExtension.showToast] and
  /// [ToastListExtension.hideToast] over calling this method directly.
  static ToastListOverlayState of<T>(BuildContext context) {
    assert(debugCheckHasToastListOverlay<T>(context));

    final _ToastListScope scope =
        context.dependOnInheritedWidgetOfExactType<_ToastListScope>()!;
    return scope._toastListOverlayState;
  }

  @override
  ToastListOverlayState<T> createState() => ToastListOverlayState<T>();
}

/// The state of a [ToastListOverlay], used to show and hide toasts.
///
/// Usually obtained through [ToastListExtension.showToast] and
/// [ToastListExtension.hideToast].
class ToastListOverlayState<T> extends State<ToastListOverlay<T>> {
  final List<_ToastEntry<T>> _toasts = <_ToastEntry<T>>[];
  GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();
  OverlayEntry? _overlayEntry;

  /// The number of toasts waiting for the list of a new overlay entry to be
  /// built.
  int _pendingCount = 0;

  /// The number of toasts whose exit animation is still running.
  int _removingCount = 0;

  /// Shows [toast] in the [Overlay] of [context].
  void show(BuildContext context, T toast) {
    if (_overlayEntry == null) _insertOverlay(context);

    if (_animatedListKey.currentState != null) {
      _insert(toast);
      return;
    }

    // The list inside a new overlay entry is built during the next frame.
    // Wait for it so the entrance animation of the toast is played.
    _pendingCount++;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _pendingCount--;
        if (mounted) _insert(toast);
      })
      ..ensureVisualUpdate();
  }

  /// Hides [item] with an exit animation.
  ///
  /// [builder] builds the toast while it animates out. If it is omitted,
  /// [ToastListOverlay.itemBuilder] is used.
  ///
  /// Does nothing if [item] is not displayed.
  void removeItem(T item, [AnimatedRemovedItemBuilder? builder]) {
    final int index = _toasts.indexWhere((toast) => toast.item == item);
    if (index == -1) return;

    _removeAt(index, builder);
  }

  void _insertOverlay(BuildContext context) {
    final OverlayState overlay = Overlay.of(context);
    // A new key for each entry, so the list of a previous entry that is still
    // being unmounted is never reused.
    _animatedListKey = GlobalKey<AnimatedListState>();
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    final OverlayEntry? overlayEntry = _overlayEntry;
    if (overlayEntry == null) return;

    _overlayEntry = null;
    overlayEntry
      ..remove()
      ..dispose();
  }

  void _removeOverlayIfIdle() {
    if (_toasts.isEmpty && _pendingCount == 0 && _removingCount == 0) {
      _removeOverlay();
    }
  }

  void _insert(T toast) {
    while (_toasts.length >= widget.limit) {
      _removeAt(_toasts.length - 1);
    }

    final _ToastEntry<T> entry = _ToastEntry<T>(toast);
    entry.timer = Timer(widget.timeoutDuration, () {
      final int index = _toasts.indexOf(entry);
      if (index != -1) _removeAt(index);
    });

    _toasts.insert(0, entry);
    _animatedListKey.currentState?.insertItem(0);
  }

  void _removeAt(int index, [AnimatedRemovedItemBuilder? builder]) {
    final _ToastEntry<T> entry = _toasts.removeAt(index);
    entry.timer?.cancel();

    final AnimatedListState? animatedList = _animatedListKey.currentState;
    if (animatedList == null) {
      _removeOverlayIfIdle();
      return;
    }

    _removingCount++;
    var isListening = false;
    animatedList.removeItem(index, (context, animation) {
      // The builder is called on every frame of the exit animation, but the
      // listener must only be added once.
      if (!isListening) {
        isListening = true;
        void handleStatusChange(AnimationStatus status) {
          if (status != AnimationStatus.dismissed) return;

          animation.removeStatusListener(handleStatusChange);
          _removingCount--;
          _removeOverlayIfIdle();
        }

        animation.addStatusListener(handleStatusChange);
      }

      return builder != null
          ? builder(context, animation)
          : widget.itemBuilder(context, entry.item, index, animation);
    });
  }

  Widget _buildOverlay(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: widget.position,
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.width),
            child: AnimatedList(
              key: _animatedListKey,
              reverse: widget.reverse,
              initialItemCount: _toasts.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index, animation) => widget.itemBuilder(
                context,
                _toasts[index].item,
                index,
                animation,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(ToastListOverlay<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void dispose() {
    for (final _ToastEntry<T> toast in _toasts) {
      toast.timer?.cancel();
    }
    _toasts.clear();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ToastListScope(
      toastListOverlayState: this,
      child: widget.child,
    );
  }
}

class _ToastEntry<T> {
  _ToastEntry(this.item);

  final T item;
  Timer? timer;
}

class _ToastListScope extends InheritedWidget {
  const _ToastListScope({
    required super.child,
    required ToastListOverlayState toastListOverlayState,
  }) : _toastListOverlayState = toastListOverlayState;

  final ToastListOverlayState _toastListOverlayState;

  @override
  bool updateShouldNotify(_ToastListScope old) =>
      _toastListOverlayState != old._toastListOverlayState;
}
