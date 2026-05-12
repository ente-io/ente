import 'dart:io';

import "package:exif_reader/exif_reader.dart";
import "package:photos/utils/exif_util.dart";

class ImageDimensionMetadata {
  final int width;
  final int height;
  final int? rawWidth;
  final int? rawHeight;
  final int? rotationDegrees;

  const ImageDimensionMetadata({
    required this.width,
    required this.height,
    this.rawWidth,
    this.rawHeight,
    this.rotationDegrees,
  });

  factory ImageDimensionMetadata.fromRawDimensions({
    required int rawWidth,
    required int rawHeight,
    required int rotationDegrees,
  }) {
    final normalizedRotation = normalizeRotationDegrees(rotationDegrees);
    final shouldSwap = isSidewaysRotation(normalizedRotation);
    return ImageDimensionMetadata(
      width: shouldSwap ? rawHeight : rawWidth,
      height: shouldSwap ? rawWidth : rawHeight,
      rawWidth: rawWidth,
      rawHeight: rawHeight,
      rotationDegrees: normalizedRotation,
    );
  }

  factory ImageDimensionMetadata.displayOnly({
    required int width,
    required int height,
    int? rotationDegrees,
  }) {
    return ImageDimensionMetadata(
      width: width,
      height: height,
      rotationDegrees: rotationDegrees == null
          ? null
          : normalizeRotationDegrees(rotationDegrees),
    );
  }

  bool get hasRawDimensions => (rawWidth ?? 0) > 0 && (rawHeight ?? 0) > 0;
}

int normalizeRotationDegrees(int degrees) {
  final normalized = degrees % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

bool isSidewaysRotation(int degrees) {
  final normalized = normalizeRotationDegrees(degrees);
  return normalized == 90 || normalized == 270;
}

int rotationDegreesFromExifOrientation(int orientation) {
  switch (orientation) {
    case 3:
    case 4:
      return 180;
    case 5:
      return 270;
    case 6:
    case 7:
      return 90;
    case 8:
      return 270;
    default:
      return 0;
  }
}

ImageDimensionMetadata? imageDimensionMetadataFromExifOrFallback(
  Map<String, IfdTag>? exifData, {
  int? fallbackWidth,
  int? fallbackHeight,
  bool applyExifOrientationToFallback = false,
}) {
  final exifDimensions = imageDimensionMetadataFromExif(exifData);
  if (exifDimensions != null) {
    return exifDimensions;
  }
  if ((fallbackWidth ?? 0) > 0 && (fallbackHeight ?? 0) > 0) {
    final displayWidth = fallbackWidth!;
    final displayHeight = fallbackHeight!;
    final orientation = exifData?['Image Orientation']?.values.firstAsInt();
    if (applyExifOrientationToFallback && orientation != null) {
      final rotationDegrees = rotationDegreesFromExifOrientation(orientation);
      final shouldSwap = isSidewaysRotation(rotationDegrees);
      return ImageDimensionMetadata.displayOnly(
        width: shouldSwap ? displayHeight : displayWidth,
        height: shouldSwap ? displayWidth : displayHeight,
        rotationDegrees: rotationDegrees,
      );
    }
    return ImageDimensionMetadata.displayOnly(
      width: displayWidth,
      height: displayHeight,
    );
  }
  return null;
}

ImageDimensionMetadata? imageDimensionMetadataFromExif(
  Map<String, IfdTag>? exifData,
) {
  final rawWidth = firstPositiveExifDimension(exifData, const [
    'EXIF ExifImageWidth',
    'Image ImageWidth',
  ]);
  final rawHeight = firstPositiveExifDimension(exifData, const [
    'EXIF ExifImageLength',
    'Image ImageLength',
  ]);
  if (rawWidth == null || rawHeight == null) {
    return null;
  }
  final orientation = exifData?['Image Orientation']?.values.firstAsInt() ?? 1;
  return ImageDimensionMetadata.fromRawDimensions(
    rawWidth: rawWidth,
    rawHeight: rawHeight,
    rotationDegrees: rotationDegreesFromExifOrientation(orientation),
  );
}

Future<ImageDimensionMetadata?> tryReadImageDimensionMetadata(File file) async {
  try {
    return imageDimensionMetadataFromExif(await readExifAsync(file));
  } catch (_) {
    return null;
  }
}

int? firstPositiveExifDimension(
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
