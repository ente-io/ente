// ignore: implementation_imports

import "package:exif_reader/exif_reader.dart";
import "package:image/image.dart";
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
  final sourceFile = await getFile(enteFile);
  if (sourceFile == null) {
    return false;
  }
  final exifData = await readExifAsync(sourceFile);
  final bool? isPanorama = checkPanoramaFromEXIF(exifData);
  if (isPanorama != null && isPanorama) {
    return true;
  }
  try {
    final result = XMPExtractor().extract(sourceFile.readAsBytesSync());
    if (checkPanoramaFromXMP(result)) {
      return true;
    }
  } catch (_) {}
  return false;
}

bool checkPanoramaFromXMP(Map<String, dynamic> xmpData) {
  if (xmpData["GPano:ProjectionType"] == "cylindrical" ||
      xmpData["GPano:ProjectionType"] == "equirectangular") {
    return true;
  }
  return false;
}

bool? checkPanoramaFromEXIF(Map<String, IfdTag>? exifData) {
  if (exifData == null) {
    return null;
  }
  if (exifData.containsKey('GPano:UsePanoramaViewer')) {
    return true;
  }
  final element = exifData["EXIF CustomRendered"];
  if (element?.printable == null) return null;
  return element?.printable == "6";
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
