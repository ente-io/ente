import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file.dart';

Future<void> deleteFiles(List<File> files,
    {bool deleteEveryWhere = false}) async {
  await PhotoManager.editor
      .deleteWithIds(files.map((file) => file.localID).toList());
  for (File file in files) {
    deleteEveryWhere
        ? await FilesDB.instance.markForDeletion(file)
        : await FilesDB.instance.delete(file);
  }
}

void preloadFile(File file) {
  // TODO
}

void preloadLocalFileThumbnail(File file) {
  if (file.localID == null ||
      ThumbnailLruCache.get(file, THUMBNAIL_SMALL_SIZE) != null) {
    return;
  }
  file.getAsset().then((asset) {
    asset
        .thumbDataWithSize(THUMBNAIL_SMALL_SIZE, THUMBNAIL_SMALL_SIZE)
        .then((data) {
      ThumbnailLruCache.put(file, THUMBNAIL_SMALL_SIZE, data);
    });
  });
}
