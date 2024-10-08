import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    directoryPath ??= (await getLibraryDirectory()).path;

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

  static String migratedNamingChanges = "migrated_naming_changes.b5";
  static migrateNamingChanges() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    if (sharedPrefs.containsKey(migratedNamingChanges)) {
      return;
    }
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
    Directory oldDataDir;
    Directory newDataDir;

    if (Platform.isLinux) {
      oldDataDir = Directory(
        p.join(dataHome.path, "ente_auth"),
      );
      newDataDir = Directory(
        p.join(dataHome.path, "enteauth"),
      );
    } else {
      oldDataDir = Directory(
        p.join(
          (await getApplicationDocumentsDirectory()).path,
          "ente",
        ),
      );
      newDataDir = Directory(
        p.join(
          (await getApplicationSupportDirectory()).path,
        ),
      );
    }
    await newDataDir.create(recursive: true);

    File newDatabaseFile =
        File(p.join(newDataDir.path, ".ente.authenticator.db"));
    if (await databaseFile.exists() && !await newDatabaseFile.exists()) {
      await databaseFile.copy(newDatabaseFile.path);
    }

    File newOfflineDatabaseFile =
        File(p.join(newDataDir.path, ".ente.offline_authenticator.db"));
    if (await offlineDatabaseFile.exists() &&
        !await newOfflineDatabaseFile.exists()) {
      await offlineDatabaseFile.copy(newOfflineDatabaseFile.path);
    }

    if (Platform.isLinux && await oldDataDir.exists()) {
      // execute shell command to recursively copy old data dir to new data dir
      final result = await Process.run(
        "cp",
        [
          "-r",
          oldDataDir.path,
          newDataDir.path,
        ],
      );
      if (result.exitCode != 0) {
        logger.warning("Failed to copy old data dir to new data dir");
        return;
      }
    }

    sharedPrefs.setBool(migratedNamingChanges, true).ignore();
  }
}
