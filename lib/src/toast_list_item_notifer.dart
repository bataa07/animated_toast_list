import 'package:flutter/foundation.dart';

class ToastListItemNotifier<T> with ChangeNotifier {
  final List<T> _list;

  ToastListItemNotifier() : _list = [];

  List<T> get listItem => _list;

  void insert(int index, T item) {
    _list.insert(index, item);
  }

  void add(T item) {
    _list.add(item);
  }

  T remove(int index) {
    T removedItem = _list.removeAt(index);

    return removedItem;
  }
}
