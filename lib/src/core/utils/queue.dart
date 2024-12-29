class Queue<T> {
  final List<T> _list = [];

  void enqueue(T element) {
    _list.add(element);
  }

  T? dequeue() {
    if (_list.isEmpty) {
      return null;
    }
    return _list.removeAt(0);
  }

  T? peek() {
    if (_list.isEmpty) {
      return null;
    }
    return _list.first;
  }

  bool get isEmpty => _list.isEmpty;

  int get length => _list.length;
}
