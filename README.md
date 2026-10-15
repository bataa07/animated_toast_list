# animated_toast_list

[![pub package](https://img.shields.io/pub/v/animated_toast_list.svg)](https://pub.dev/packages/animated_toast_list)
[![CI](https://github.com/bataa07/animated_toast_list/actions/workflows/ci.yml/badge.svg)](https://github.com/bataa07/animated_toast_list/actions/workflows/ci.yml)

A minimal, dependency-free toast list for Flutter.
**You design the toast. The package stacks, animates and hides it.**

- **Your design:** there are no built-in styles. A toast is any widget you build, with any animation.
- **Any type:** a toast can be a `String`, your own model class, or a sealed class with a subtype for each kind of toast.
- **Minimal:** two extension methods on `BuildContext`, no dependencies besides Flutter.
- Works on all platforms, and stays above the current screen while navigating.

## [Live demo](https://snowyday.site/)

# Installation

```sh
flutter pub add animated_toast_list
```

Requires Flutter 3.10 or newer (Dart 3).

# Usage

Wrap your `MaterialApp` (or `CupertinoApp`, `WidgetsApp`) with `ToastListOverlay` and build your toast in `itemBuilder`. Use the `animation` for the entrance and exit transitions. For more details, see [the example](https://github.com/bataa07/animated_toast_list/blob/develop/example/lib/main.dart).

```dart
Widget build(BuildContext context) {
  return ToastListOverlay<MyToastModel>(
    itemBuilder: (context, item, index, animation) =>
        ToastItem(animation: animation, item: item),
    child: MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const MainScreen(),
    ),
  );
}
```

| **Property** | **Default value** | **Description** |
|---|---|---|
| **child** | Required Widget | The wrapped widget. |
| **itemBuilder** | Required ToastListItemBuilder<T> | Builds the toast widget. |
| **position** | Alignment.topCenter | Where the toasts are displayed. |
| **reverse** | false | Displays the newest toast at the bottom instead of the top. |
| **limit** | 5 | The maximum number of toasts displayed at the same time. When the limit is reached, the oldest toast is hidden. |
| **width** | 375 | The maximum width of the toasts. |
| **timeoutDuration** | 5 seconds | How long a toast is displayed. |

## Show a toast

Call `context.showToast` from any widget below the `ToastListOverlay`. You can see more details in [the example](https://github.com/bataa07/animated_toast_list/blob/develop/example/lib/main.dart).

```dart
context.showToast(MyToastModel('Saved', ToastType.success));

// Displayed for 10 seconds instead of timeoutDuration.
context.showToast(
  MyToastModel('Check your connection', ToastType.warning),
  duration: const Duration(seconds: 10),
);

// Not hidden automatically.
context.showToast(
  MyToastModel('Update available', ToastType.info),
  persist: true,
);
```

> **Note:** `MyToastModel` is an example model. Any type can be used as a toast.

## Hide a toast

Call `context.hideToast` with the toast. It is animated out with your `itemBuilder`.

```dart
context.hideToast(item);
```

To animate it out with a different widget, pass a builder:

```dart
context.hideToast(
  item,
  (context, animation) => ToastItem(animation: animation, item: item),
);
```

`showToast` returns a `ToastHandle`, which hides exactly that toast, even if other displayed toasts are equal to it:

```dart
final toast = context.showToast(
  MyToastModel('Uploading…', ToastType.info),
  persist: true,
);
await upload();
toast.hide();
```

## Different kinds of toasts

Toasts whose type is a subtype of the type argument of `ToastListOverlay` can be shown, so a sealed class works well:

```dart
sealed class AppToast {}

class SuccessToast extends AppToast {}

class ErrorToast extends AppToast {
  ErrorToast(this.message);

  final String message;
}

ToastListOverlay<AppToast>(
  itemBuilder: (context, toast, index, animation) => switch (toast) {
    SuccessToast() => MySuccessToast(animation: animation),
    ErrorToast(:final message) =>
      MyErrorToast(message: message, animation: animation),
  },
  child: MaterialApp(home: const HomeScreen()),
);

context.showToast(ErrorToast('Something went wrong'));
```

## Accessibility

Since you build the toast, wrap it with `Semantics(liveRegion: true, child: ...)` so screen readers announce it when it appears, as in [the example](https://github.com/bataa07/animated_toast_list/blob/develop/example/lib/main.dart).

# Example

The figure below shows when the toast exceeds the limit.
![2022-06-11_01-25-41_AdobeExpress](https://user-images.githubusercontent.com/89500759/173130420-087d0f0c-6329-4aba-8080-9d714de631b4.gif)

The figure below shows how to remove the toast by clicking the close button.
![2022-06-11_01-25-41_AdobeExpress (1)](https://user-images.githubusercontent.com/89500759/173130435-0fdf874c-9436-40aa-87fc-b8bf714b524e.gif)

In the figure below, you can see the toast without any problems even if you navigate to another screen.
![2022-06-11_01-25-41_AdobeExpress (2)](https://user-images.githubusercontent.com/89500759/173130457-e0111ce9-b8e3-4358-816c-dcd8881abd68.gif)

The figure below shows the toast list reversed.
![2022-06-11_01-39-18_AdobeExpress](https://user-images.githubusercontent.com/89500759/173130469-906e485c-c884-4d58-b893-eac6751ebb08.gif)
