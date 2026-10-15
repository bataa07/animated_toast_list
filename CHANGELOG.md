## 2.0.0

- **Breaking:** requires Dart 3 and Flutter 3.10 or newer.
- **Breaking:** removed the internal members that were exposed by mistake:
  `ToastTimer`, `ToastListOverlayState.countdownTimer`,
  `ToastListOverlayState.timerList`,
  `ToastListOverlayState.listItemChangeListener` and
  `ToastListOverlayState.disposeAll`.
- **Breaking:** `showToast` throws a descriptive error when no `Overlay` is
  found, instead of silently ignoring the toast. When it is called while
  widgets build, the error is reported with `FlutterError.reportError`.
- The builder of `hideToast` is now optional. When it is omitted, the
  `itemBuilder` is used to animate the toast out.
- `showToast` returns a `ToastHandle`, which hides exactly that toast.
- `showToast` accepts a `duration` (#13, thanks @yeikel16), and
  `persist: true` for toasts that are not hidden after a timeout.
- Add `useSafeArea`, which can be set to false to display the toasts edge to
  edge (#12).
- Toasts whose type is a subtype of the type argument of `ToastListOverlay`
  can be shown, for example the subclasses of a sealed class. Previously the
  types had to match exactly.
- Nested `ToastListOverlay`s with different type arguments are supported.
- Toasts are displayed in the closest `Overlay` above the `ToastListOverlay`,
  or in the `Overlay` of the root `Navigator` when it wraps the app. Toasts
  shown from a nested `Navigator`, such as the one of a tab or of a go_router
  `ShellRoute`, are no longer hidden by other tabs or routes, and toasts move
  to the new `Overlay` when the app is rebuilt with a new key.
- `showToast`, `hideToast` and `ToastHandle.hide` can be called in
  `initState` and `dispose`, and `showToast` with a context above the
  `Navigator`, such as the context of a navigator key or of
  `MaterialApp.builder`.
- Fix a new toast not being displayed until another frame was rendered, for
  example when it was shown from a `GestureDetector` (#9).
- Fix a toast disappearing when it was shown right after the last toast was
  hidden.
- Fix the periodic timer leaking and still running after the
  `ToastListOverlay` was disposed.
- Fix the `index` passed to the `itemBuilder` when a toast times out.
- Changes to `position`, `reverse`, `width`, `useSafeArea` and `itemBuilder`
  now apply to displayed toasts, and lowering `limit` hides the extra toasts.
- Add API documentation and tests.
- Update the example app to the latest Flutter, with new screenshots.

## 1.0.2

- remove warning `Try replacing the operator '?.' with '.'`

## 1.0.1

- fix `Error: AnimationController.dispose() called more than once.`

## 1.0.0

- update README.md
- update pubspec.yaml

## 0.0.1

- initial release.
