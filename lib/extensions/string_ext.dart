extension StringExtensionsNullSafe on String? {
  int get sumAsciiValues {
    if (this == null) {
      return -1;
    }
    int sum = 0;
    for (int i = 0; i < this!.length; i++) {
      sum += this!.codeUnitAt(i);
    }
    return sum;
  }
}
