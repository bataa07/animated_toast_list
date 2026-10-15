## 2.0.0

- **Breaking:** requires Dart 3 and Flutter 3.10 or newer.
- **Breaking:** removed the internal members that were exposed by mistake:
  `ToastTimer`, `ToastListOverlayState.countdownTimer`,
  `ToastListOverlayState.timerList`,
  `ToastListOverlayState.listItemChangeListener` and
  `ToastListOverlayState.disposeAll`.
- The builder of `hideToast` is now optional. When it is omitted, the
  `itemBuilder` is used to animate the toast out.
- Fix a new toast not being displayed until another frame was rendered.
- Fix a toast disappearing when it was shown right after the last toast was
  hidden.
- Fix the periodic timer leaking and still running after the
  `ToastListOverlay` was disposed.
- Fix the `index` passed to the `itemBuilder` when a toast times out.
- Changes to `position`, `reverse`, `width` and `itemBuilder` now apply to
  displayed toasts.
- Throw a descriptive error when no `Overlay` is found instead of silently
  ignoring it.
- Add API documentation and tests.
- Update the example app to the latest Flutter.

## 1.0.2

- remove warning `Try replacing the operator '?.' with '.'`

## 1.0.1

- fix `Error: AnimationController.dispose() called more than once.`

## 1.0.0

- update README.md
- update pubspec.yaml

## 0.0.1

- initial release.
