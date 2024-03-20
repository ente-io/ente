import 'dart:math' as math show log;

class FaceDetectionOptionsYOLO {
  final double minScoreSigmoidThreshold;
  final double iouThreshold;
  final int inputWidth;
  final int inputHeight;
  final int numCoords;
  final int numKeypoints;
  final int numValuesPerKeypoint;
  final int maxNumFaces;
  final double scoreClippingThresh;
  final double inverseSigmoidMinScoreThreshold;
  final bool useSigmoidScore;
  final bool flipVertically;

  FaceDetectionOptionsYOLO({
    required this.minScoreSigmoidThreshold,
    required this.iouThreshold,
    required this.inputWidth,
    required this.inputHeight,
    this.numCoords = 14,
    this.numKeypoints = 5,
    this.numValuesPerKeypoint = 2,
    this.maxNumFaces = 100,
    this.scoreClippingThresh = 100.0,
    this.useSigmoidScore = true,
    this.flipVertically = false,
  }) : inverseSigmoidMinScoreThreshold =
            math.log(minScoreSigmoidThreshold / (1 - minScoreSigmoidThreshold));
}