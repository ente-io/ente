import 'package:photo_manager/photo_manager.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file.dart';

Future<void> deleteFiles(List<File> files,
    {bool deleteEveryWhere = false}) async {
  await PhotoManager.editor
      .deleteWithIds(files.map((file) => file.localId).toList());
  for (File file in files) {
    deleteEveryWhere
        ? await FilesDB.instance.markForDeletion(file)
        : await FilesDB.instance.delete(file);
  }
}
