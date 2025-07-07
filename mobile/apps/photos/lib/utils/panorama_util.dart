// ignore: implementation_imports

import "package:exif_reader/exif_reader.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/services/file_magic_service.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/file_util.dart";

/// Check if the file is a panorama image.
Future<bool> _checkIfPanorama(EnteFile enteFile) async {
  if (enteFile.fileType != FileType.image) {
    return false;
  }
  final sourceFile = await getFile(enteFile);
  if (sourceFile == null) {
    return false;
  }
  final exifData = await readExifAsync(sourceFile);
  final bool? isPanorama = isPanoFromExif(exifData);
  if (isPanorama != null && isPanorama) {
    return true;
  }
  try {
    final xmpData = await getXmp(sourceFile);
    if (isPanoFromXmp(xmpData)) {
      return true;
    }
  } catch (_) {}
  return false;
}

bool isPanoFromXmp(Map<String, dynamic> xmpData) {
  if (xmpData["GPano:ProjectionType"] == "cylindrical" ||
      xmpData["GPano:ProjectionType"] == "equirectangular") {
    return true;
  }
  return false;
}

bool? isPanoFromExif(Map<String, IfdTag>? exifData) {
  if (exifData == null) {
    return null;
  }
  if (exifData.containsKey('GPano:UsePanoramaViewer')) {
    final usePanoramaViewer =
        exifData['GPano:UsePanoramaViewer']?.printable.toLowerCase();
    if (usePanoramaViewer == '1' || usePanoramaViewer == 'true') {
      return true;
    }
  }
  if (exifData.containsKey('GPano:ProjectionType')) {
    final projectionType =
        exifData['GPano:ProjectionType']?.printable.toLowerCase();
    return projectionType == 'cylindrical' ||
        projectionType == 'equirectangular';
  }
  final element = exifData["EXIF CustomRendered"];
  if (element?.printable == null) return null;
  return element?.printable == "6";
}

// guardedCheckPanorama() method is used to check if the file is a panorama image.
Future<void> guardedCheckPanorama(EnteFile file) async {
  if (file.isPanorama() != null || !file.canEditMetaInfo) {
    return;
  }
  final result = await _checkIfPanorama(file);

  // Update the metadata if it is not updated
  if (file.canEditMetaInfo && file.isPanorama() == null) {
    int? mediaType = file.rAsset?.mediaType;
    mediaType ??= 0;

    mediaType = mediaType | (result ? 1 : 0);

    FileMagicService.instance.updatePublicMagicMetadata(
      [file],
      {mediaTypeKey: mediaType},
    ).ignore();
  }
}
