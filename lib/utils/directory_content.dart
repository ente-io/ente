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

Future<void> deleteDirectoryContents(String directoryPath) async {
  // Mark variables as final if they don't need to be modified
  final directory = Directory(directoryPath);
  final contents = await directory.list().toList();

  // Iterate through the list and delete each file or directory
  for (final fileOrDirectory in contents) {
    await fileOrDirectory.delete();
  }
}

Future<int> getFileSize(String path) async {
  final file = File(path);
  return await file.exists() ? await file.length() : 0;
}
