import "dart:io";

import "package:flutter/foundation.dart";
import "package:photos/core/cache/lru_map.dart";
import "package:photos/face/model/box.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/utils/face/face_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/thumbnail_util.dart";
import "package:pool/pool.dart";

final LRUMap<String, Uint8List?> faceCropCache = LRUMap(1000);
final pool = Pool(10, timeout: const Duration(seconds: 15));
Future<Map<String, Uint8List>?> getFaceCrops(
  EnteFile file,
  Map<String, FaceBox> faceBoxeMap,
) async {
  late String? imagePath;
  if (file.fileType != FileType.video) {
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
      // await ImageMlIsolate.instance.generateFaceThumbnailsForImage(
      await generateJpgFaceThumbnails(
    imagePath,
    faceBoxes,
  );
  final Map<String, Uint8List> result = {};
  for (int i = 0; i < faceIds.length; i++) {
    result[faceIds[i]] = faceCrop[i];
  }
  return result;
}
