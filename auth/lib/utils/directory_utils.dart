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

  static migrateNamingChanges() async {
    final databaseFile = File(
      p.join(
        (await getApplicationDocumentsDirectory()).path,
        "ente",
        ".ente.authenticator.db",
      ),
    );
    final offlineDatabaseFile = File(
      p.join(
        (await getApplicationDocumentsDirectory()).path,
        "ente",
        ".ente.offline_authenticator.db",
      ),
    );

    final oldDataDir = Directory(
      p.join(dataHome.path, "ente_auth"),
    );
    final newDir = Directory(
      p.join(dataHome.path, "enteauth"),
    );
    await newDir.create(recursive: true);

    if (await databaseFile.exists()) {
      await databaseFile.rename(
        p.join(newDir.path, ".ente.authenticator.db"),
      );
    }

    if (await offlineDatabaseFile.exists()) {
      await offlineDatabaseFile.rename(
        p.join(newDir.path, ".ente.offline_authenticator.db"),
      );
    }

    if (await oldDataDir.exists()) {
      await oldDataDir.list().forEach((file) async {
        await file.rename(p.join(newDir.path, p.basename(file.path)));
      });
      await oldDataDir.delete(recursive: true);
    }
  }
}
