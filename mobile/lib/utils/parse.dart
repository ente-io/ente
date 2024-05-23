import "package:flutter/foundation.dart";

int parseKeyAsInt(Map<String, dynamic> map, String key, int defaultValue) {
  try {
    return map[key] ?? defaultValue;
  } catch (e) {
    if (kDebugMode) {
      print("Error parsing key $key as int: $e");
    }
    final double val = map[key] as double;
    return val.toInt();
  }
}
