# animated_toast_list example

An example app that shows how to use the
[animated_toast_list](https://pub.dev/packages/animated_toast_list) package.

```sh
flutter run
```

- [`lib/sample_app.dart`](lib/sample_app.dart) wraps the app with
  `ToastListOverlay` and defines how a toast looks.
- [`lib/main_screen.dart`](lib/main_screen.dart) shows toasts with
  `context.showToast`.
- [`lib/toast_item.dart`](lib/toast_item.dart) is the toast widget, which hides
  itself with `context.hideToast`.
