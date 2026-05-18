import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";

const int kDefaultImagePreviewMaxPixels = 32000000; // 32MP
const int kLowRamImagePreviewMaxPixels = 16000000; // 16MP
const int kAutomaticImageAnalysisMaxPixels = 50000000; // 50MP

bool isImageLikeFile(EnteFile file) {
  return file.fileType == FileType.image || file.fileType == FileType.livePhoto;
}

int? knownPixelCount(EnteFile file) {
  if (!isImageLikeFile(file) || !file.hasDimensions) {
    return null;
  }
  return file.width * file.height;
}

bool isKnownImageLargerThan(EnteFile file, int maxPixels) {
  final pixelCount = knownPixelCount(file);
  return pixelCount != null && pixelCount > maxPixels;
}

bool shouldSkipAutomaticImageAnalysis(EnteFile file) {
  return isKnownImageLargerThan(file, kAutomaticImageAnalysisMaxPixels);
}

String imageDimensionsForLogs(EnteFile file) {
  if (!file.hasDimensions) {
    return "unknown";
  }
  return "${file.width}x${file.height}";
}
