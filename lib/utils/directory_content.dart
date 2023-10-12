import 'dart:io';

class DirectoryStat {
  final String path;
  final List<DirectoryStat> subDirectory;
  final Map<String, int> fileNameToSize;
  final int size;

  DirectoryStat(this.path, this.subDirectory, this.fileNameToSize, this.size);

  int get total => fileNameToSize.length + subDirectory.length;
}

Future<DirectoryStat> getDirectorySize(Directory directory) async {
  int size = 0;
  final List<DirectoryStat> subDirectories = [];
  final Map<String, int> fileNameToSize = {};

  if (await directory.exists()) {
    final List<FileSystemEntity> entities = directory.listSync();
    for (FileSystemEntity entity in entities) {
      if (entity is File) {
        int fileSize = await File(entity.path).length();
        size += fileSize;
        fileNameToSize[entity.uri.pathSegments.last] = fileSize;
      } else if (entity is Directory) {
        DirectoryStat subDirStat =
            await getDirectorySize(Directory(entity.path));
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
