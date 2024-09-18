import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xdg_directories/xdg_directories.dart';

class DirectoryUtils {
  static final logger = Logger('DirectoryUtils');

  static Future<String> getDatabasePath(String databaseName) async {
    String? directoryPath;

    if (Platform.isLinux) {
      try {
        directoryPath = dataHome.path;
      } catch (e) {
        logger.warning("Failed to get dataHome: $e");
      }
    }

    directoryPath ??= (await getApplicationDocumentsDirectory()).path;

    return p.joinAll(
      [
        directoryPath,
        "enteauth",
        ".$databaseName",
      ],
    );
  }

  static Future<Directory> getDirectoryForInit() async {
    Directory? directory;
    if (Platform.isLinux) {
      try {
        return cacheHome;
      } catch (e) {
        logger.warning("Failed to get cacheHome: $e");
      }
    }

    directory ??= await getApplicationDocumentsDirectory();

    return Directory(p.join(directory.path, "enteauthinit"));
  }

  static Future<Directory> getTempsDir() async {
    return await getTemporaryDirectory();
  }
}
