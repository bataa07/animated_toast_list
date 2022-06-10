#  Introduction

When using Flutter, did you ever want to show toast with the design you want? Also, did you want to list the toast and show it with the desired animation? Then you have found what you are looking for!
This package is generic, so there will be no problem with your toast.
This package supports all platforms.

#  Usage

To use this package, wrap any widget with ToastListOverlay, as in the example below. For more details, see [the example](https://github.com/bataa07/animated_toast_list/blob/develop/example/lib/sample_app.dart).
```
Widget build(BuildContext context) {
    return ToastListOverlay<MyToastModel>(
      itemBuilder: (BuildContext context, MyToastModel item, int index,
          Animation<double> animation) {
        return ToastItem(
          animation: animation,
          item: item,
          onTap: () => context.hideToast(
              item,
              (context, animation) =>
                  _buildItem(context, item, index, animation)),
        );
      },
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
```
| **Property** | **Default value** | **Description** |
|---|---|---|
| **child** | Required Widget | Wrapped widget |
| **position** | Alignment.topCenter | Specifies where toast to be displayed. |
| **reverse** | false | Reverse the Toast list. |
| **limit** | 5 | Specify how much toast to display. |
| **itemBuilder** | Required ToastListItemBuilder<T> | The Toast widget is defined here. |
| **width** | 375 | Specifies the width of the toast. |
| **timeoutDuration** | 5 seconds | Specifies how long toast will be displayed. |
  
Now you can call the context.showToast method to display your toast. You can see more details in [the example](https://github.com/bataa07/animated_toast_list/blob/develop/example/lib/main_screen.dart).
```
  context.showToast(MyToastModel(ToastType.success.name, ToastType.success));
```
> **Note:** MyToastModel is an example model.

To close the Toast, call the context.hideToast method.
```
context.hideToast(
  item,
  (context, animation) => ToastItem(
    animation: animation,
    item: item,
  ),
);
```

#  Example
  
The figure below shows when the toast exceeds the limit. 
  
![2022-06-11_01-25-41_AdobeExpress](https://user-images.githubusercontent.com/89500759/173130420-087d0f0c-6329-4aba-8080-9d714de631b4.gif)

The figure below shows how to remove the toast by clicking the close button.

![2022-06-11_01-25-41_AdobeExpress (1)](https://user-images.githubusercontent.com/89500759/173130435-0fdf874c-9436-40aa-87fc-b8bf714b524e.gif)

In the figure below, you can see the toast without any problems even if you navigate to another screen.
![2022-06-11_01-25-41_AdobeExpress (2)](https://user-images.githubusercontent.com/89500759/173130457-e0111ce9-b8e3-4358-816c-dcd8881abd68.gif)
  
The figure below shows the toast list reversed.
  
![2022-06-11_01-39-18_AdobeExpress](https://user-images.githubusercontent.com/89500759/173130469-906e485c-c884-4d58-b893-eac6751ebb08.gif)
  


