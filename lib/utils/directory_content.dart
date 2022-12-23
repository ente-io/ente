import 'dart:io';

class DirectoryStat {
  final int subDirectoryCount;
  final int size;
  final int fileCount;

  DirectoryStat(this.subDirectoryCount, this.size, this.fileCount);
}

Future<DirectoryStat> getDirectorySize(Directory directory) async {
  int size = 0;
  int subDirCount = 0;
  int fileCount = 0;

  if (await directory.exists()) {
    // Get a list of all the files and directories in the directory
    final List<FileSystemEntity> entities = directory.listSync();
    // Iterate through the list of entities and add the sizes of the files to the total size
    for (FileSystemEntity entity in entities) {
      if (entity is File) {
        size += (await File(entity.path).length());
        fileCount++;
      } else if (entity is Directory) {
        subDirCount++;
        // If the entity is a directory, recursively calculate its size
        final DirectoryStat subDirStat =
            await getDirectorySize(Directory(entity.path));
        size += subDirStat.size;
        subDirCount += subDirStat.subDirectoryCount;
        fileCount += subDirStat.fileCount;
      }
    }
  }
  return DirectoryStat(subDirCount, size, fileCount);
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
