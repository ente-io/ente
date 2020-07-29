import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';

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

void preloadFile(File file) {
  if (file.fileType == FileType.video) {
    return;
  }
  if (file.localId == null) {
    if (BytesLruCache.get(file) == null) {
      file.getBytes().then((data) {
        BytesLruCache.put(file, data);
      });
    }
  } else {
    if (FileLruCache.get(file) == null) {
      file.getAsset().then((asset) {
        asset.file.then((assetFile) {
          FileLruCache.put(file, assetFile);
        });
      });
    }
  }
}
