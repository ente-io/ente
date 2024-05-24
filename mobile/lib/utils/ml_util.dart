import "package:photos/core/configuration.dart";
import "package:photos/db/files_db.dart";

Future<List<int>> getIndexableFileIDs() async {
    return FilesDB.instance
        .getOwnedFileIDs(Configuration.instance.getUserID()!);
  }