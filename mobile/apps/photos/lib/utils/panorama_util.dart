// ignore: implementation_imports
import "package:motion_photos/src/xmp_extractor.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/services/file_magic_service.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/file_util.dart";

/// Check if the file is a panorama image.
Future<bool> checkIfPanorama(EnteFile enteFile) async {
  if (enteFile.fileType != FileType.image) {
    return false;
  }
  final file = await getFile(enteFile);
  if (file == null) {
    return false;
  }
  try {
    final result = XMPExtractor().extract(file.readAsBytesSync());
    if (checkPanoramaFromXMP(result)) {
      return true;
    }
  } catch (_) {}

  final result = await readExifAsync(file);

  final element = result["EXIF CustomRendered"];
  return element?.printable == "6";
}

bool checkPanoramaFromXMP(Map<String, dynamic> xmpData) {
  if (xmpData["GPano:ProjectionType"] == "cylindrical" ||
      xmpData["GPano:ProjectionType"] == "equirectangular") {
    return true;
  }
  return false;
}

// guardedCheckPanorama() method is used to check if the file is a panorama image.
Future<void> guardedCheckPanorama(EnteFile file) async {
  if (file.isPanorama() != null) {
    return;
  }
  final result = await checkIfPanorama(file);

  // Update the metadata if it is not updated
  if (file.canEditMetaInfo && file.isPanorama() == null) {
    int? mediaType = file.pubMagicMetadata?.mediaType;
    mediaType ??= 0;

    mediaType = mediaType | (result ? 1 : 0);

    FileMagicService.instance.updatePublicMagicMetadata(
      [file],
      {mediaTypeKey: mediaType},
    ).ignore();
  }
}
