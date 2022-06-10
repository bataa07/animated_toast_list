import 'package:animated_toast_list/src/toast_list_overlay.dart';
import 'package:flutter/widgets.dart';

/// Asserts that the given context has a [ToastListOverlay] ancestor.
///
/// Used by various widgets to make sure that they are only used in an
/// appropriate context.
///
/// To invoke this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasToastListOverlay(context));
/// ```
///
/// This method can be expensive (it walks the element tree).
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasToastListOverlay<T>(BuildContext context) {
  assert(() {
    if (context.findAncestorWidgetOfExactType<ToastListOverlay<T>>() == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No ToastListOverlay widget found.'),
        ErrorDescription(
            '${context.widget.runtimeType} widgets require a ToastListOverlay widget ancestor.'),
        ...context.describeMissingAncestor(
            expectedAncestorType: ToastListOverlay<T>),
      ]);
    }
    return true;
  }());
  return true;
}
