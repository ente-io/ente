import "package:flutter/painting.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/utils/file_util.dart";

/// Check if the file is a panorama image.
Future<bool> checkIfPanorama(EnteFile enteFile) async {
  if (enteFile.fileType != FileType.image) {
    return false;
  }
  if (enteFile.isPanorama() != null) {
    return enteFile.isPanorama()!;
  }
  final file = await getFile(enteFile);
  if (file == null) {
    return false;
  }

  final image = await decodeImageFromList(await file.readAsBytes());
  final width = image.width.toDouble();
  final height = image.height.toDouble();

  if (height > width) {
    return height / width >= 2.0;
  }
  return width / height >= 2.0;
}
