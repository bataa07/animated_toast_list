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
    this.useSafeArea = true,
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

  /// Whether the toasts avoid the parts of the screen that are covered by the
  /// system, such as the status bar, the notch and the home indicator.
  ///
  /// Set it to false to display the toasts edge to edge, for example a toast
  /// that fills the bottom of the screen.
  final bool useSafeArea;

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
abstract final class ToastHandle {
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
  /// The duration of the entrance and exit animations of the list.
  static const Duration _animationDuration = Duration(milliseconds: 300);

  /// The displayed toasts, the newest first.
  final List<_ToastEntry<T>> _toasts = <_ToastEntry<T>>[];

  /// The toasts waiting for the list of a new overlay entry to be built, the
  /// newest last.
  final List<_ToastEntry<T>> _pendingToasts = <_ToastEntry<T>>[];

  /// The toasts whose exit animation is still running.
  final List<_ToastEntry<T>> _removingToasts = <_ToastEntry<T>>[];

  GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();
  OverlayState? _overlay;
  OverlayEntry? _overlayEntry;

  /// Whether [_overlay] is below this widget, so that the overlay entry can
  /// be rebuilt while this widget builds.
  bool _isOverlayBelow = false;

  bool _accepts<S>() => <S>[] is List<T>;

  /// Shows [toast] in the [Overlay] of the app, usually the one of the root
  /// [Navigator].
  ///
  /// The toast is hidden after [duration], or after
  /// [ToastListOverlay.timeoutDuration] if [duration] is null. If [persist]
  /// is true, the toast is not hidden after a timeout.
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

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // The overlay cannot change while widgets build, for example when the
      // toast is shown in initState. Show it after the frame instead.
      _pendingToasts.add(entry);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // The toast is no longer pending if it was hidden in the meantime.
        if (!mounted || !_pendingToasts.remove(entry)) return;
        _show(context.mounted ? context : this.context, entry);
      });
      return entry;
    }

    _show(context, entry);
    return entry;
  }

  void _show(BuildContext context, _ToastEntry<T> entry) {
    _ensureOverlay(context);

    if (_animatedListKey.currentState != null) {
      _insert(entry);
      return;
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
  }

  /// Hides [item] with an exit animation.
  ///
  /// [builder] builds the toast while it animates out. If it is omitted,
  /// [ToastListOverlay.itemBuilder] is used.
  ///
  /// If several toasts are equal to [item], the newest one is hidden. Does
  /// nothing if [item] is not displayed.
  void removeItem(T item, [AnimatedRemovedItemBuilder? builder]) {
    // The pending toasts are newer than the displayed ones.
    final int pending = _pendingToasts.lastIndexWhere(
      (toast) => toast.item == item,
    );
    if (pending != -1) {
      _hide(_pendingToasts[pending], builder);
      return;
    }

    final int index = _toasts.indexWhere((toast) => toast.item == item);
    if (index != -1) _removeAt(index, builder);
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

  void _ensureOverlay(BuildContext context) {
    final OverlayState? overlay = _overlay;
    if (overlay != null) {
      if (overlay.mounted) return;

      // The Overlay was disposed, for example because the app was rebuilt
      // with a new key. Move the displayed toasts to a new overlay entry.
      for (final _ToastEntry<T> toast in _removingToasts) {
        toast.timer?.cancel();
      }
      _removingToasts.clear();
      _removeOverlay();
    }
    _insertOverlay(context);
  }

  void _insertOverlay(BuildContext context) {
    _overlay = _findOverlay(context);

    // A new key for each entry, so the list of a previous entry that is still
    // being unmounted is never reused.
    _animatedListKey = GlobalKey<AnimatedListState>();
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    _overlay!.insert(_overlayEntry!);
  }

  OverlayState _findOverlay(BuildContext context) {
    // Use the outermost Overlay between this widget and context, usually the
    // one of the root Navigator. The closest Overlay can belong to a nested
    // Navigator, such as the one of a tab, which is hidden or covered when
    // another tab or a route of the root Navigator is displayed.
    OverlayState? between;
    var isBelow = false;
    if (context != this.context) {
      context.visitAncestorElements((element) {
        if (element == this.context) {
          isBelow = true;
          return false;
        }
        if (element is StatefulElement && element.state is OverlayState) {
          between = element.state as OverlayState;
        }
        return true;
      });
    }
    _isOverlayBelow = true;
    if (isBelow && between != null) return between!;

    // When context is above the Overlays, for example the context of
    // MaterialApp.builder or of a navigator key, use the outermost Overlay
    // below this widget.
    final OverlayState? below = _findOverlayBelow();
    if (below != null) return below;

    // When this widget is below the Overlays, for example when it wraps a
    // screen of a Navigator, use the closest one above it.
    _isOverlayBelow = false;
    return Overlay.of(context);
  }

  OverlayState? _findOverlayBelow() {
    // Breadth first, so the outermost Overlay is found first.
    var elements = <Element>[];
    context.visitChildElements(elements.add);
    while (elements.isNotEmpty) {
      final children = <Element>[];
      for (final Element element in elements) {
        if (element is StatefulElement && element.state is OverlayState) {
          return element.state as OverlayState;
        }
        element.visitChildElements(children.add);
      }
      elements = children;
    }
    return null;
  }

  void _removeOverlay() {
    final OverlayEntry? overlayEntry = _overlayEntry;
    if (overlayEntry == null) return;

    _overlay = null;
    _overlayEntry = null;
    overlayEntry
      ..remove()
      ..dispose();
  }

  void _removeOverlayIfIdle() {
    if (_toasts.isEmpty && _pendingToasts.isEmpty && _removingToasts.isEmpty) {
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
    _animatedListKey.currentState?.insertItem(
      0,
      duration: _animationDuration,
    );
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

    _removingToasts.add(entry);
    var isListening = false;
    // The list does not call the builder of a toast that is not built, for
    // example a toast below the screen or one hidden in the frame it was
    // shown. The removal is then finished when the animation would end.
    entry.timer = Timer(_animationDuration, () {
      if (!isListening) _finishRemoval(entry);
    });
    animatedList.removeItem(
      index,
      (context, animation) {
        // The builder is called on every frame of the exit animation, but the
        // listener must only be added once.
        if (!isListening) {
          isListening = true;
          void handleStatusChange(AnimationStatus status) {
            if (status != AnimationStatus.dismissed) return;

            animation.removeStatusListener(handleStatusChange);
            _finishRemoval(entry);
          }

          animation.addStatusListener(handleStatusChange);
        }

        return builder != null
            ? builder(context, animation)
            : widget.itemBuilder(context, entry.item, index, animation);
      },
      duration: _animationDuration,
    );
  }

  void _finishRemoval(_ToastEntry<T> entry) {
    entry.timer?.cancel();
    if (!_removingToasts.remove(entry)) return;

    // The list disposes the animation of the removed toast in a microtask.
    // Removing the overlay entry during this frame can unmount the list
    // before that microtask on the web, which disposes the animation twice.
    // Wait until the frame is done instead.
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted) _removeOverlayIfIdle();
      })
      ..ensureVisualUpdate();
  }

  Widget _buildOverlay(BuildContext context) {
    final Widget toasts = Align(
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
            // Otherwise the list adds the padding of the MediaQuery, which
            // SafeArea already handles.
            padding: EdgeInsets.zero,
            itemBuilder: (context, index, animation) => widget.itemBuilder(
              context,
              _toasts[index].item,
              index,
              animation,
            ),
          ),
        ),
      ),
    );

    return widget.useSafeArea ? SafeArea(child: toasts) : toasts;
  }

  @override
  void didUpdateWidget(ToastListOverlay<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_overlayEntry == null) return;

    if (_isOverlayBelow) {
      _overlayEntry!.markNeedsBuild();
    } else {
      // Rebuilding an overlay entry that is not below this widget is not
      // allowed while this widget builds.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _overlayEntry?.markNeedsBuild();
      });
    }

    if (widget.limit < oldWidget.limit) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        while (_toasts.length > widget.limit) {
          _removeAt(_toasts.length - 1);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final _ToastEntry<T> toast in <_ToastEntry<T>>[
      ..._pendingToasts,
      ..._toasts,
      ..._removingToasts,
    ]) {
      toast
        .._isShowing = false
        ..timer?.cancel();
    }
    _pendingToasts.clear();
    _toasts.clear();
    _removingToasts.clear();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

final class _ToastEntry<T> implements ToastHandle {
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

  /// Hides the toast after its timeout, or finishes its removal.
  Timer? timer;
  bool _isShowing = true;

  @override
  bool get isShowing => _isShowing;

  @override
  void hide([AnimatedRemovedItemBuilder? builder]) =>
      _state._hide(this, builder);
}
