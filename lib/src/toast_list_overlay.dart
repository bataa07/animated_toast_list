import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
/// The type argument [T] is the type of the toast items. Toasts of type [T]
/// and its subtypes can be shown, so a sealed class or a common supertype
/// can be used for different kinds of toasts.
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
  ///
  /// Can be overridden for a single toast with the `duration` argument of
  /// [ToastListExtension.showToast].
  final Duration timeoutDuration;

  /// Where the toasts are displayed on the screen.
  final Alignment position;

  /// Whether the newest toast is displayed at the bottom of the list instead
  /// of the top.
  final bool reverse;

  /// The maximum number of toasts displayed at the same time.
  ///
  /// When a new toast is shown and the limit is reached, the oldest toast is
  /// hidden, even if it persists.
  final int limit;

  /// Builds the widget of each toast.
  final ToastListItemBuilder<T> itemBuilder;

  /// The maximum width of the toasts.
  final double width;

  /// Returns the state of the closest [ToastListOverlay] ancestor of
  /// [context] that can display toasts of type [T].
  ///
  /// That is the closest [ToastListOverlay] whose type argument is [T] or a
  /// supertype of [T].
  ///
  /// Prefer [ToastListExtension.showToast] and
  /// [ToastListExtension.hideToast] over calling this method directly.
  static ToastListOverlayState of<T>(BuildContext context) {
    ToastListOverlayState? result;
    context.visitAncestorElements((element) {
      if (element is StatefulElement) {
        final State state = element.state;
        if (state is ToastListOverlayState && state._accepts<T>()) {
          result = state;
          return false;
        }
      }
      return true;
    });

    if (result == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No ToastListOverlay widget found.'),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require a ToastListOverlay '
          'widget ancestor whose type argument is $T or a supertype of $T.',
        ),
        ErrorHint(
          'Wrap your app with a ToastListOverlay<$T>. If the toast is a '
          'subtype of the type argument of your ToastListOverlay, make sure '
          'it is not typed as dynamic or as an unrelated type, or pass the '
          'type argument explicitly, for example showToast<MyToast>(toast).',
        ),
        ...context.describeMissingAncestor(
          expectedAncestorType: ToastListOverlay,
        ),
      ]);
    }
    return result!;
  }

  @override
  ToastListOverlayState<T> createState() => ToastListOverlayState<T>();
}

/// A toast shown with [ToastListExtension.showToast].
///
/// Use it to hide a specific toast, for example a toast that persists until
/// a task is done.
abstract class ToastHandle {
  /// Whether the toast is displayed or about to be displayed.
  ///
  /// Becomes false as soon as the toast starts to hide.
  bool get isShowing;

  /// Hides the toast with an exit animation.
  ///
  /// [builder] builds the toast while it animates out. If it is omitted,
  /// [ToastListOverlay.itemBuilder] is used.
  ///
  /// Does nothing if the toast is already hidden.
  void hide([AnimatedRemovedItemBuilder? builder]);
}

/// The state of a [ToastListOverlay], used to show and hide toasts.
///
/// Usually obtained through [ToastListExtension.showToast] and
/// [ToastListExtension.hideToast].
class ToastListOverlayState<T> extends State<ToastListOverlay<T>> {
  /// The displayed toasts, the newest first.
  final List<_ToastEntry<T>> _toasts = <_ToastEntry<T>>[];

  /// The toasts waiting for the list of a new overlay entry to be built.
  final List<_ToastEntry<T>> _pendingToasts = <_ToastEntry<T>>[];

  GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();
  OverlayEntry? _overlayEntry;

  /// The number of toasts whose exit animation is still running.
  int _removingCount = 0;

  bool _accepts<S>() => <S>[] is List<T>;

  /// Shows [toast] in the [Overlay] of [context].
  ///
  /// The toast is hidden after [duration], or after
  /// [ToastListOverlay.timeoutDuration] if [duration] is null. If [persist]
  /// is true, the toast is not hidden automatically.
  ToastHandle show(
    BuildContext context,
    T toast, {
    Duration? duration,
    bool persist = false,
  }) {
    final _ToastEntry<T> entry = _ToastEntry<T>(
      this,
      toast,
      duration: duration,
      persist: persist,
    );

    if (_overlayEntry == null) _insertOverlay(context);

    if (_animatedListKey.currentState != null) {
      _insert(entry);
      return entry;
    }

    // The list inside a new overlay entry is built during the next frame.
    // Wait for it so the entrance animation of the toast is played.
    _pendingToasts.add(entry);
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        // The toast is no longer pending if it was hidden in the meantime.
        if (mounted && _pendingToasts.remove(entry)) _insert(entry);
      })
      ..ensureVisualUpdate();
    return entry;
  }

  /// Hides [item] with an exit animation.
  ///
  /// [builder] builds the toast while it animates out. If it is omitted,
  /// [ToastListOverlay.itemBuilder] is used.
  ///
  /// If several displayed toasts are equal to [item], the newest one is
  /// hidden. Does nothing if [item] is not displayed.
  void removeItem(T item, [AnimatedRemovedItemBuilder? builder]) {
    final int index = _toasts.indexWhere((toast) => toast.item == item);
    if (index == -1) return;

    _removeAt(index, builder);
  }

  void _hide(_ToastEntry<T> entry, AnimatedRemovedItemBuilder? builder) {
    if (!entry._isShowing) return;

    final int index = _toasts.indexOf(entry);
    if (index != -1) {
      _removeAt(index, builder);
    } else if (_pendingToasts.remove(entry)) {
      entry._isShowing = false;
      _removeOverlayIfIdle();
    }
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
    if (_toasts.isEmpty && _pendingToasts.isEmpty && _removingCount == 0) {
      _removeOverlay();
    }
  }

  void _insert(_ToastEntry<T> entry) {
    while (_toasts.length >= widget.limit) {
      _removeAt(_toasts.length - 1);
    }

    if (!entry.persist) {
      entry.timer = Timer(
        entry.duration ?? widget.timeoutDuration,
        () => _hide(entry, null),
      );
    }

    _toasts.insert(0, entry);
    _animatedListKey.currentState?.insertItem(0);
  }

  void _removeAt(int index, [AnimatedRemovedItemBuilder? builder]) {
    final _ToastEntry<T> entry = _toasts.removeAt(index);
    entry
      .._isShowing = false
      ..timer?.cancel();

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
          // The list disposes the animation of the removed toast in a
          // microtask. Removing the overlay entry during this frame can
          // unmount the list before that microtask on the web, which disposes
          // the animation twice. Wait until the frame is done instead.
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) _removeOverlayIfIdle();
          });
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
    for (final _ToastEntry<T> toast in <_ToastEntry<T>>[
      ..._pendingToasts,
      ..._toasts,
    ]) {
      toast
        .._isShowing = false
        ..timer?.cancel();
    }
    _pendingToasts.clear();
    _toasts.clear();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ToastEntry<T> implements ToastHandle {
  _ToastEntry(
    this._state,
    this.item, {
    required this.duration,
    required this.persist,
  });

  final ToastListOverlayState<T> _state;
  final T item;
  final Duration? duration;
  final bool persist;
  Timer? timer;
  bool _isShowing = true;

  @override
  bool get isShowing => _isShowing;

  @override
  void hide([AnimatedRemovedItemBuilder? builder]) =>
      _state._hide(this, builder);
}
