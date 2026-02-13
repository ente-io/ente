import "package:photos/db/device_files_db.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file/file.dart";

String getDownloadSkipToastFileName(
  EnteFile file, {
  required String fallbackFileName,
}) {
  final title = (file.title ?? "").trim();
  final displayName = file.displayName.trim();
  return title.isNotEmpty
      ? title
      : displayName.isNotEmpty
          ? displayName
          : fallbackFileName;
}

Future<String?> getExistingLocalFolderNameForDownloadSkipToast(
  EnteFile file,
) async {
  if (file.localID == null) {
    return null;
  }
  final asset = await file.getAsset;
  if (asset == null || !(await asset.exists)) {
    return null;
  }
  final folderNames =
      await FilesDB.instance.getDeviceCollectionNamesForLocalID(file.localID!);
  if (folderNames.isNotEmpty) {
    return folderNames.last;
  }
  throw StateError(
    "Expected non-empty device collection name for localID=${file.localID}, "
    "but found none.",
  );
}
