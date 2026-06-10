import 'dart:io';

import "package:exif_reader/exif_reader.dart";
import "package:photos/utils/exif_util.dart";

const int largeImageDimensionBackfillMinPixels = 100000000; // 100MP

class ImageDimensionMetadata {
  final int width;
  final int height;

  const ImageDimensionMetadata({required this.width, required this.height});

  int get pixels => width * height;
}

bool shouldSwapDimensionsForExifOrientation(int orientation) {
  return orientation >= 5 && orientation <= 8;
}

ImageDimensionMetadata? imageDimensionMetadataFromExif(
  Map<String, IfdTag>? exifData,
) {
  final rawWidth = _firstPositiveExifDimension(exifData, const [
    'EXIF ExifImageWidth',
    'Image ImageWidth',
  ]);
  final rawHeight = _firstPositiveExifDimension(exifData, const [
    'EXIF ExifImageLength',
    'Image ImageLength',
  ]);
  if (rawWidth == null || rawHeight == null) {
    return null;
  }
  final orientation = exifData?['Image Orientation']?.values.firstAsInt() ?? 1;
  return _displayDimensions(
    rawWidth: rawWidth,
    rawHeight: rawHeight,
    exifOrientation: orientation,
  );
}

Future<ImageDimensionMetadata?> tryReadImageDimensionMetadata(File file) async {
  try {
    return imageDimensionMetadataFromExif(await readExifAsync(file));
  } catch (_) {
    return null;
  }
}

ImageDimensionMetadata _displayDimensions({
  required int rawWidth,
  required int rawHeight,
  required int exifOrientation,
}) {
  final shouldSwap = shouldSwapDimensionsForExifOrientation(exifOrientation);
  return ImageDimensionMetadata(
    width: shouldSwap ? rawHeight : rawWidth,
    height: shouldSwap ? rawWidth : rawHeight,
  );
}

int? _firstPositiveExifDimension(
  Map<String, IfdTag>? exifData,
  List<String> keys,
) {
  if (exifData == null) {
    return null;
  }
  for (final key in keys) {
    final value = exifData[key]?.values.firstAsInt();
    if (value != null && value > 0) {
      return value;
    }
  }
  return null;
}
