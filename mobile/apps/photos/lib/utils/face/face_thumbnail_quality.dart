import 'package:photos/core/constants.dart' show thumbnailLargeSize;
import 'package:photos/models/ml/face/box.dart';

const int kFaceThumbnailTargetShortSide = 512;
const double kFaceThumbnailRegularPadding = 0.4;
const double kFaceThumbnailMinimumPadding = 0.1;

class FaceThumbnailUpgradeDecision {
  final bool shouldUpgrade;
  final String reason;
  final double thumbnailUpscaleFactor;
  final double fullUpscaleFactor;
  final double improvementRatio;

  const FaceThumbnailUpgradeDecision({
    required this.shouldUpgrade,
    required this.reason,
    required this.thumbnailUpscaleFactor,
    required this.fullUpscaleFactor,
    required this.improvementRatio,
  });
}

typedef ImageDimensions = ({int width, int height});

ImageDimensions? estimateThumbnailDimensionsFromFullDimensions({
  required int fullWidth,
  required int fullHeight,
  int thumbnailMaxSide = thumbnailLargeSize,
}) {
  if (fullWidth <= 0 || fullHeight <= 0 || thumbnailMaxSide <= 0) {
    return null;
  }

  if (fullWidth <= thumbnailMaxSide && fullHeight <= thumbnailMaxSide) {
    return (width: fullWidth, height: fullHeight);
  }

  if (fullWidth >= fullHeight) {
    return (
      width: thumbnailMaxSide,
      height: _max(1, (fullHeight * thumbnailMaxSide / fullWidth).round()),
    );
  }

  return (
    width: _max(1, (fullWidth * thumbnailMaxSide / fullHeight).round()),
    height: thumbnailMaxSide,
  );
}

FaceThumbnailUpgradeDecision shouldUpgradeFromThumbnail({
  required FaceBox faceBox,
  required int thumbnailWidth,
  required int thumbnailHeight,
  required int fullWidth,
  required int fullHeight,
  double upscaleThreshold = 1.6,
  double minImprovementRatio = 1.4,
}) {
  final thumbnailCropShortSide = _computeCropShortSide(
    faceBox,
    imageWidth: thumbnailWidth,
    imageHeight: thumbnailHeight,
  );
  if (thumbnailCropShortSide == null || thumbnailCropShortSide <= 0) {
    return const FaceThumbnailUpgradeDecision(
      shouldUpgrade: false,
      reason: 'invalid_thumbnail_crop',
      thumbnailUpscaleFactor: 0,
      fullUpscaleFactor: 0,
      improvementRatio: 0,
    );
  }

  final fullCropShortSide = _computeCropShortSide(
    faceBox,
    imageWidth: fullWidth,
    imageHeight: fullHeight,
  );
  if (fullCropShortSide == null || fullCropShortSide <= 0) {
    return const FaceThumbnailUpgradeDecision(
      shouldUpgrade: false,
      reason: 'invalid_full_crop',
      thumbnailUpscaleFactor: 0,
      fullUpscaleFactor: 0,
      improvementRatio: 0,
    );
  }

  final thumbnailUpscaleFactor =
      kFaceThumbnailTargetShortSide / thumbnailCropShortSide;
  if (thumbnailUpscaleFactor <= upscaleThreshold) {
    return FaceThumbnailUpgradeDecision(
      shouldUpgrade: false,
      reason: 'below_upscale_threshold',
      thumbnailUpscaleFactor: thumbnailUpscaleFactor,
      fullUpscaleFactor: 0,
      improvementRatio: 0,
    );
  }

  final fullUpscaleFactor = kFaceThumbnailTargetShortSide / fullCropShortSide;
  final improvementRatio = thumbnailUpscaleFactor / fullUpscaleFactor;
  if (improvementRatio < minImprovementRatio) {
    return FaceThumbnailUpgradeDecision(
      shouldUpgrade: false,
      reason: 'insufficient_improvement',
      thumbnailUpscaleFactor: thumbnailUpscaleFactor,
      fullUpscaleFactor: fullUpscaleFactor,
      improvementRatio: improvementRatio,
    );
  }

  return FaceThumbnailUpgradeDecision(
    shouldUpgrade: true,
    reason: 'upgrade_needed',
    thumbnailUpscaleFactor: thumbnailUpscaleFactor,
    fullUpscaleFactor: fullUpscaleFactor,
    improvementRatio: improvementRatio,
  );
}

double? _computeCropShortSide(
  FaceBox faceBox, {
  required int imageWidth,
  required int imageHeight,
}) {
  if (imageWidth <= 0 || imageHeight <= 0) {
    return null;
  }

  final width = imageWidth.toDouble();
  final height = imageHeight.toDouble();

  final xMinAbs = faceBox.x * width;
  final yMinAbs = faceBox.y * height;
  final widthAbs = faceBox.width * width;
  final heightAbs = faceBox.height * height;

  if (widthAbs <= 0 || heightAbs <= 0) {
    return null;
  }

  final xCrop = xMinAbs - widthAbs * kFaceThumbnailRegularPadding;
  final xOvershoot = (xCrop < 0 ? -xCrop : 0) / widthAbs;
  final widthCrop = widthAbs * (1 + 2 * kFaceThumbnailRegularPadding) -
      2 *
          _min(
            xOvershoot,
            kFaceThumbnailRegularPadding - kFaceThumbnailMinimumPadding,
          ) *
          widthAbs;

  final yCrop = yMinAbs - heightAbs * kFaceThumbnailRegularPadding;
  final yOvershoot = (yCrop < 0 ? -yCrop : 0) / heightAbs;
  final heightCrop = heightAbs * (1 + 2 * kFaceThumbnailRegularPadding) -
      2 *
          _min(
            yOvershoot,
            kFaceThumbnailRegularPadding - kFaceThumbnailMinimumPadding,
          ) *
          heightAbs;

  final xCropSafe = xCrop.clamp(0, width).toDouble();
  final yCropSafe = yCrop.clamp(0, height).toDouble();
  final widthCropSafe = widthCrop.clamp(0, width - xCropSafe).toDouble();
  final heightCropSafe = heightCrop.clamp(0, height - yCropSafe).toDouble();

  final shortSide = _min(widthCropSafe, heightCropSafe);
  return shortSide > 0 ? shortSide : null;
}

double _min(double a, double b) => a <= b ? a : b;

int _max(int a, int b) => a >= b ? a : b;
