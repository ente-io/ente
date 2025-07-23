import 'dart:io';

import "package:path/path.dart";
import "package:photos/utils/standalone/data.dart";

class DirectoryStat {
  final String path;
  final List<DirectoryStat> subDirectory;
  final Map<String, int> fileNameToSize;
  final int size;

  DirectoryStat(this.path, this.subDirectory, this.fileNameToSize, this.size);

  int get total => fileNameToSize.length + subDirectory.length;

  int get fileCount => fileNameToSize.length;
}

const int _oneMB = 1048576;
const int _tenMB = 10485760;

String prettyPrintDirectoryStat(
  DirectoryStat dirStat,
  String rootPath, [
  String indent = '',
  int minDirSizeForPrint = _tenMB,
  int minFileSizeForPrint = _oneMB,
]) {
  final StringBuffer buffer = StringBuffer();
  _buildPrettyString(
    dirStat,
    rootPath,
    buffer,
    indent,
    minDirSizeForPrint,
    minFileSizeForPrint,
  );
  return buffer.toString();
}

void _buildPrettyString(
  DirectoryStat dirStat,
  String rootPath,
  StringBuffer buffer,
  String indent,
  int minDirSizeForPrint,
  int minFileSizeForPrint,
) {
  if (dirStat.size < minDirSizeForPrint) {
    return;
  }
  final String relativePath = dirStat.path.replaceFirst(rootPath, '');

  if (relativePath.isEmpty) {
    buffer.writeln(
      'Root: ${basename(dirStat.path)} [SubDir:${dirStat.subDirectory.length} Files:${dirStat.fileNameToSize.length}], Size:${formatBytes(dirStat.size)}',
    );
  } else {
    buffer.writeln(
      '${indent}Directory: $relativePath, [SubDir:${dirStat.subDirectory.length} Files:${dirStat.fileNameToSize.length}], Size: ${formatBytes(dirStat.size)}',
    );
  }

  for (var subDir in dirStat.subDirectory) {
    _buildPrettyString(
      subDir,
      rootPath,
      buffer,
      '$indent  ',
      minDirSizeForPrint,
      minFileSizeForPrint,
    );
  }

  for (var fileName in dirStat.fileNameToSize.keys) {
    final int fSize = dirStat.fileNameToSize[fileName]!;
    if (fSize <= minFileSizeForPrint) {
      continue;
    }
    buffer.writeln('$indent  File: $fileName, Size: ${formatBytes(fSize)}');
  }
}

Future<DirectoryStat> getDirectoryStat(
  Directory directory, {
  String? prefix,
}) async {
  int size = 0;
  final List<DirectoryStat> subDirectories = [];
  final Map<String, int> fileNameToSize = {};

  if (await directory.exists()) {
    final List<FileSystemEntity> entities = directory.listSync();
    for (FileSystemEntity entity in entities) {
      if (prefix != null && !entity.path.contains(prefix)) {
        continue;
      }

      if (entity is File) {
        final int fileSize = await File(entity.path).length();
        size += fileSize;
        fileNameToSize[entity.uri.pathSegments.last] = fileSize;
      } else if (entity is Directory) {
        final DirectoryStat subDirStat =
            await getDirectoryStat(Directory(entity.path));
        subDirectories.add(subDirStat);
        size += subDirStat.size;
      }
    }
  }
  return DirectoryStat(directory.path, subDirectories, fileNameToSize, size);
}

Future<void> deleteDirectoryContents(String directoryPath) async {
  // Mark variables as final if they don't need to be modified
  final directory = Directory(directoryPath);
  if (!(await directory.exists())) {
    return;
  }
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
