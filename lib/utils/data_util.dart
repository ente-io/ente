import 'dart:math';

double convertBytesToGBs(final int bytes, {int precision = 2}) {
  return double.parse(
      (bytes / (1024 * 1024 * 1024)).toStringAsFixed(precision));
}

final kStorageUnits = ["bytes", "KB", "MB", "GB"];

String convertBytesToReadableFormat(int bytes) {
  int storageUnitIndex = 0;
  while (bytes >= 1024 && storageUnitIndex < kStorageUnits.length - 1) {
    storageUnitIndex++;
    bytes = (bytes / 1024).round();
  }
  return bytes.toString() + " " + kStorageUnits[storageUnitIndex];
}

String formatBytes(int bytes, [int decimals = 2]) {
  if (bytes == 0) return '0 bytes';
  const k = 1024;
  int dm = decimals < 0 ? 0 : decimals;
  int i = (log(bytes) / log(k)).floor();
  return ((bytes / pow(k, i)).toStringAsFixed(dm)) + ' ' + kStorageUnits[i];
}
