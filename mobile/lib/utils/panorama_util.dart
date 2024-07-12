import "dart:io";

import "package:photos/utils/exif_util.dart";
import "package:xmp/xmp.dart";

Future<bool> checkIfPanorama(File file) async {
  try {
    final result = XMP.extract(file.readAsBytesSync());

    if (result["Rdf Projectiontype"] == "cylindrical") {
      return true;
    }
  } catch (_) {}

  final result = await readExifAsync(file);

  final element = result["EXIF CustomRendered"];
  return element?.printable == "6";
}
