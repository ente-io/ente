import "dart:io" show File;

import "package:flutter/foundation.dart";
import "package:photos/core/cache/lru_map.dart";
import "package:photos/face/model/box.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/image_isolate.dart";
import "package:photos/utils/thumbnail_util.dart";
import "package:pool/pool.dart";

void resetPool({required bool fullFile}) {
  if (fullFile) {
    poolFullFileFaceGenerations =
        Pool(20, timeout: const Duration(seconds: 15));
  } else {
    poolThumbnailFaceGenerations =
        Pool(100, timeout: const Duration(seconds: 15));
  }
}

const int retryLimit = 3;
final LRUMap<String, Uint8List?> faceCropCache = LRUMap(1000);
final LRUMap<String, Uint8List?> faceCropThumbnailCache = LRUMap(1000);
Pool poolFullFileFaceGenerations =
    Pool(20, timeout: const Duration(seconds: 15));
Pool poolThumbnailFaceGenerations =
    Pool(100, timeout: const Duration(seconds: 15));
Future<Map<String, Uint8List>?> getFaceCrops(
  EnteFile file,
  Map<String, FaceBox> faceBoxeMap, {
  bool useFullFile = true,
}) async {
  late String? imagePath;
  if (useFullFile && file.fileType != FileType.video) {
    final File? ioFile = await getFile(file);
    if (ioFile == null) {
      return null;
    }
    imagePath = ioFile.path;
  } else {
    final thumbnail = await getThumbnailForUploadedFile(file);
    if (thumbnail == null) {
      return null;
    }
    imagePath = thumbnail.path;
  }
  final List<String> faceIds = [];
  final List<FaceBox> faceBoxes = [];
  for (final e in faceBoxeMap.entries) {
    faceIds.add(e.key);
    faceBoxes.add(e.value);
  }
  final List<Uint8List> faceCrop =
      await ImageIsolate.instance.generateFaceThumbnails(
    // await generateJpgFaceThumbnails(
    imagePath,
    faceBoxes,
  );
  final Map<String, Uint8List> result = {};
  for (int i = 0; i < faceIds.length; i++) {
    result[faceIds[i]] = faceCrop[i];
  }
  return result;
}
