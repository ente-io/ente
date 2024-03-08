import "dart:io";

import "package:flutter/foundation.dart";
import "package:photos/core/cache/lru_map.dart";
import "package:photos/face/model/box.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/image_ml_isolate.dart";
import "package:photos/utils/thumbnail_util.dart";
import "package:pool/pool.dart";

final LRUMap<String, Uint8List?> faceCropCache = LRUMap(1000);
final pool = Pool(5, timeout: const Duration(seconds: 15));
Future<Map<String, Uint8List>?> getFaceCrops(
  EnteFile file,
  Map<String, FaceBox> faceBoxeMap,
) async {
  late Uint8List? ioFileBytes;
  if (file.fileType != FileType.video) {
    final File? ioFile = await getFile(file);
    if (ioFile == null) {
      return null;
    }
    ioFileBytes = await ioFile.readAsBytes();
  } else {
    ioFileBytes = await getThumbnail(file);
  }
  final List<String> faceIds = [];
  final List<FaceBox> faceBoxes = [];
  for (final e in faceBoxeMap.entries) {
    faceIds.add(e.key);
    faceBoxes.add(e.value);
  }
  final List<Uint8List> faceCrop =
      await ImageMlIsolate.instance.generateFaceThumbnailsForImage(
    ioFileBytes!,
    faceBoxes,
  );
  final Map<String, Uint8List> result = {};
  for (int i = 0; i < faceIds.length; i++) {
    result[faceIds[i]] = faceCrop[i];
  }
  return result;
}
