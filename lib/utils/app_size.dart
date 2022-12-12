import 'dart:io';

import 'package:flutter/foundation.dart';

Future<Map<String, int>> directoryStat(String dirPath) async {
  int fileCount = 0;
  int totalSizeInBytes = 0;
  final dir = Directory(dirPath);
  try {
    if (await dir.exists()) {
      dir
          .listSync(recursive: true, followLinks: false)
          .forEach((FileSystemEntity entity) {
        if (entity is File) {
          fileCount++;
          totalSizeInBytes += entity.lengthSync();
        }
      });
    }
  } catch (e) {
    debugPrint(e.toString());
  }

  return {'fileCount': fileCount, 'size': totalSizeInBytes};
}

Future<int> getFileSize(String path) async {
  final file = File(path);
  return await file.exists() ? await file.length() : 0;
}
