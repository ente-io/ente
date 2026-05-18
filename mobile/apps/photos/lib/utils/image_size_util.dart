import "package:photos/models/file/file.dart";

const int kDefaultImagePreviewMaxPixels = 32000000; // 32MP
const int kLowRamImagePreviewMaxPixels = 16000000; // 16MP

int? knownPixelCount(EnteFile file) {
  if (!file.hasDimensions) {
    return null;
  }
  return file.width * file.height;
}

bool isKnownImageLargerThan(EnteFile file, int maxPixels) {
  final pixelCount = knownPixelCount(file);
  return pixelCount != null && pixelCount > maxPixels;
}
