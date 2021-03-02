double convertBytesToGBs(final int bytes, {int precision = 2}) {
  return double.parse(
      (bytes / (1024 * 1024 * 1024)).toStringAsFixed(precision));
}

final kStorageUnits = ["bytes", "KB", "MB", "GB", "TB"];

String convertBytesToReadableFormat(int bytes) {
  int storageUnitIndex = 0;
  while (bytes >= 1024) {
    storageUnitIndex++;
    bytes = (bytes / 1024).round();
  }
  return bytes.toString() + " " + kStorageUnits[storageUnitIndex];
}
