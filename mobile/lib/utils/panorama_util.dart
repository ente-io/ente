import "package:flutter/painting.dart";
import "package:photos/models/file/file.dart";
import "package:photos/utils/file_util.dart";

Future<bool> checkIfPanorama(EnteFile enteFile) async {
  if (enteFile.height > 0 && enteFile.width > 0) {
    if (enteFile.height > enteFile.width) {
      return enteFile.height / enteFile.width >= 2.0;
    }
    return enteFile.width / enteFile.height >= 2.0;
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
