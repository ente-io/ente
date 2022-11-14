extension ListExtension<E> on List<E> {
  List<List<E>> chunks(int chunkSize) {
    final List<List<E>> result = <List<E>>[];
    for (var i = 0; i < length; i += chunkSize) {
      result.add(
        sublist(i, i + chunkSize > length ? length : i + chunkSize),
      );
    }
    return result;
  }
}
