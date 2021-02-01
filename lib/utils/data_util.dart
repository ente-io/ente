double convertBytesToGBs(final int bytes, {int precision = 2}) {
  return double.parse(
      (bytes / (1024 * 1024 * 1024)).toStringAsFixed(precision));
}
