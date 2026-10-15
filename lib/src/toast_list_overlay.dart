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
///   child: const MaterialApp(home: HomeScreen()),
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

  /// The toasts in the list, the newest first.
  final List<_ToastEntry<T>> _toasts = <_ToastEntry<T>>[];

  /// The toasts that are not in the list yet, the newest last.
  final List<_ToastEntry<T>> _pendingToasts = <_ToastEntry<T>>[];

  /// The toasts in the list that are hidden after the frame, with the builder
  /// of their exit animation.
  final Map<_ToastEntry<T>, AnimatedRemovedItemBuilder?> _hidingToasts =
      <_ToastEntry<T>, AnimatedRemovedItemBuilder?>{};

  GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();
  OverlayState? _overlay;
  OverlayEntry? _overlayEntry;

  /// Whether [_overlay] is below this widget, so that the overlay entry can
  /// be rebuilt while this widget builds.
  bool _isOverlayBelow = false;

  /// The context of the last toast shown before the overlay entry exists.
  BuildContext? _pendingContext;
  bool _isFlushScheduled = false;
  bool _hasWaitedForList = false;

  bool _accepts<S>() => <S>[] is List<T>;

  /// Whether widgets are building, when the overlay and the list cannot
  /// change. Also true while runApp builds the first frame.
  static bool get _isBuilding =>
      SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks ||
      WidgetsBinding.instance.rootElement == null;

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
    final bool isBuilding = _isBuilding;
    // Throws when there is no Overlay. The overlay cannot change while
    // widgets build, so it is then inserted after the frame, and a missing
    // Overlay is reported then.
    if (!isBuilding) _ensureOverlay(context);

    final _ToastEntry<T> entry = _ToastEntry<T>(
      this,
      toast,
      duration: duration,
      persist: persist,
    );

    if (!isBuilding &&
        _pendingToasts.isEmpty &&
        _animatedListKey.currentState != null) {
      _insert(entry);
      return entry;
    }

    _pendingToasts.add(entry);
    _pendingContext = context;
    _scheduleFlush();
    return entry;
  }

  /// Hides [item] with an exit animation.
  ///
  /// [builder] builds the toast while it animates out. If it is omitted,
  /// [ToastListOverlay.itemBuilder] is used.
  ///
  /// If several shown toasts are equal to [item], the newest one is hidden.
  /// Does nothing if no shown toast is equal to [item].
  void removeItem(T item, [AnimatedRemovedItemBuilder? builder]) {
    // The pending toasts are newer than the ones in the list.
    final int pending = _pendingToasts.lastIndexWhere(
      (toast) => toast.item == item,
    );
    if (pending != -1) {
      _hide(_pendingToasts[pending], builder);
      return;
    }

    final int index = _toasts.indexWhere(
      (toast) => toast._isShowing && toast.item == item,
    );
    if (index != -1) _hide(_toasts[index], builder);
  }

  void _hide(_ToastEntry<T> entry, AnimatedRemovedItemBuilder? builder) {
    if (!entry._isShowing) return;

    if (_pendingToasts.remove(entry)) {
      entry._isShowing = false;
      return;
    }

    final int index = _toasts.indexOf(entry);
    if (index == -1) return;

    if (_isBuilding) {
      // The list cannot change while widgets build, for example when the
      // toast is hidden in initState or dispose. Hide it after the frame.
      entry
        .._isShowing = false
        ..timer?.cancel();
      _hidingToasts[entry] = builder;
      _scheduleFlush();
    } else {
      _removeAt(index, builder);
    }
  }

  void _scheduleFlush() {
    if (_isFlushScheduled) return;

    _isFlushScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _isFlushScheduled = false;
        if (mounted) _flush();
      })
      ..ensureVisualUpdate();
  }

  /// Applies the changes that were not allowed while widgets built.
  void _flush() {
    if (_toasts.isNotEmpty || _pendingToasts.isNotEmpty) {
      final BuildContext? pendingContext = _pendingContext;
      final BuildContext context =
          pendingContext != null && pendingContext.mounted
              ? pendingContext
              : this.context;
      try {
        _ensureOverlay(context);
      } catch (exception, stack) {
        _dropPendingToasts();
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'animated_toast_list',
            context: ErrorDescription('while showing a toast'),
          ),
        );
        return;
      }
    }
    _pendingContext = null;

    // The list of a new overlay entry is built during the next frame. Wait
    // for it so the entrance animations are played. It is not built while
    // the entry is hidden by an opaque entry above it.
    if (_overlayEntry != null &&
        _animatedListKey.currentState == null &&
        !_hasWaitedForList) {
      _hasWaitedForList = true;
      _scheduleFlush();
      return;
    }
    _hasWaitedForList = false;

    final Map<_ToastEntry<T>, AnimatedRemovedItemBuilder?> hiding =
        Map<_ToastEntry<T>, AnimatedRemovedItemBuilder?>.of(_hidingToasts);
    _hidingToasts.clear();
    hiding.forEach((entry, builder) {
      final int index = _toasts.indexOf(entry);
      if (index != -1) _removeAt(index, builder);
    });

    _removeOverLimit(widget.limit);

    final List<_ToastEntry<T>> pending = List<_ToastEntry<T>>.of(
      _pendingToasts,
    );
    _pendingToasts.clear();
    pending.forEach(_insert);
  }

  void _dropPendingToasts() {
    for (final _ToastEntry<T> toast in _pendingToasts) {
      toast._isShowing = false;
    }
    _pendingToasts.clear();
    _pendingContext = null;
  }

  /// Inserts the overlay entry if it does not exist, or if its Overlay was
  /// disposed, for example because the app was rebuilt with a new key.
  void _ensureOverlay(BuildContext context) {
    final OverlayState? overlay = _overlay;
    if (overlay != null && overlay.mounted) return;

    _removeOverlay();
    _insertOverlay(context);
  }

  void _insertOverlay(BuildContext context) {
    final (OverlayState overlay, bool isBelow) = _findOverlay(context);
    _overlay = overlay;
    _isOverlayBelow = isBelow;

    // A new key for each entry, so the list of a previous entry that is still
    // being unmounted is never reused.
    _animatedListKey = GlobalKey<AnimatedListState>();
    _overlayEntry = OverlayEntry(builder: _buildOverlay)
      ..addListener(_handleOverlayEntryChanged);
    overlay.insert(_overlayEntry!);
  }

  /// Finds the Overlay that displays the toasts, and whether it is below
  /// this widget.
  (OverlayState, bool) _findOverlay(BuildContext context) {
    // The closest Overlay above this widget covers this whole widget, and
    // stays the same when the tabs or the routes below it change.
    final OverlayState? above = Overlay.maybeOf(this.context);
    if (above != null) return (above, false);

    // When this widget is above the app, use the outermost Overlay between
    // this widget and context, usually the one of the root Navigator. The
    // closest Overlay can belong to a nested Navigator, such as the one of a
    // tab, which is hidden when another tab or route is displayed.
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
    if (isBelow && between != null) return (between!, true);

    // When context is above the Overlays, for example the context of
    // MaterialApp.builder or of a navigator key, use the outermost Overlay
    // below this widget.
    final OverlayState? below = _findOverlayBelow();
    if (below != null) return (below, true);

    // Throws a descriptive error.
    return (Overlay.of(context), false);
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

  void _handleOverlayEntryChanged() {
    // The entry is unmounted when its Overlay is disposed. Check it after the
    // frame, when the Overlay is unmounted too.
    if (!_overlayEntry!.mounted) _scheduleFlush();
  }

  void _removeOverlay() {
    final OverlayEntry? overlayEntry = _overlayEntry;
    if (overlayEntry == null) return;

    _overlay = null;
    _overlayEntry = null;
    overlayEntry
      ..removeListener(_handleOverlayEntryChanged)
      ..remove()
      ..dispose();
  }

  void _insert(_ToastEntry<T> entry) {
    _removeOverLimit(widget.limit - 1);

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

  /// Hides the oldest shown toasts until at most [limit] are shown.
  void _removeOverLimit(int limit) {
    var count = _toasts.where((toast) => toast._isShowing).length;
    for (var index = _toasts.length - 1; index >= 0 && count > limit; index--) {
      if (!_toasts[index]._isShowing) continue;

      _removeAt(index);
      count--;
    }
  }

  void _removeAt(int index, [AnimatedRemovedItemBuilder? builder]) {
    final _ToastEntry<T> entry = _toasts.removeAt(index);
    entry
      .._isShowing = false
      ..timer?.cancel();
    _hidingToasts.remove(entry);

    _animatedListKey.currentState?.removeItem(
      index,
      (context, animation) => builder != null
          ? builder(context, animation)
          : widget.itemBuilder(context, entry.item, index, animation),
      duration: _animationDuration,
    );
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

    // Hides the extra toasts after the frame.
    if (widget.limit < oldWidget.limit) _scheduleFlush();
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
    _hidingToasts.clear();
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

  /// Hides the toast after its timeout.
  Timer? timer;
  bool _isShowing = true;

  @override
  bool get isShowing => _isShowing;

  @override
  void hide([AnimatedRemovedItemBuilder? builder]) =>
      _state._hide(this, builder);
}
