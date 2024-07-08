import 'package:logging/logging.dart';
import "package:photos/services/machine_learning/face_ml/face_detection/detection.dart";
import 'package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart';

class BlurDetectionService {
  static final _logger = Logger('BlurDetectionService');

  // singleton pattern
  BlurDetectionService._privateConstructor();
  static final instance = BlurDetectionService._privateConstructor();
  factory BlurDetectionService() => instance;

  static Future<(bool, double)> predictIsBlurGrayLaplacian(
    List<List<int>> grayImage, {
    int threshold = kLaplacianHardThreshold,
    FaceDirection faceDirection = FaceDirection.straight,
  }) async {
    final List<List<int>> laplacian =
        _applyLaplacian(grayImage, faceDirection: faceDirection);
    final double variance = _calculateVariance(laplacian);
    _logger.info('Variance: $variance');
    return (variance < threshold, variance);
  }

  static double _calculateVariance(List<List<int>> matrix) {
    final int numRows = matrix.length;
    final int numCols = matrix[0].length;
    final int totalElements = numRows * numCols;

    // Calculate the mean
    double mean = 0;
    for (var row in matrix) {
      for (var value in row) {
        mean += value;
      }
    }
    mean /= totalElements;

    // Calculate the variance
    double variance = 0;
    for (var row in matrix) {
      for (var value in row) {
        final double diff = value - mean;
        variance += diff * diff;
      }
    }
    variance /= totalElements;

    return variance;
  }

  static List<List<int>> _padImage(
    List<List<int>> image, {
    int removeSideColumns = 56,
    FaceDirection faceDirection = FaceDirection.straight,
  }) {
    // Exception is removeSideColumns is not even
    if (removeSideColumns % 2 != 0) {
      throw Exception('removeSideColumns must be even');
    }

    final int numRows = image.length;
    final int numCols = image[0].length;
    final int paddedNumCols = numCols + 2 - removeSideColumns;
    final int paddedNumRows = numRows + 2;

    // Create a new matrix with extra padding
    final List<List<int>> paddedImage = List.generate(
      paddedNumRows,
      (i) => List.generate(
        paddedNumCols,
        (j) => 0,
        growable: false,
      ),
      growable: false,
    );

    // Copy original image into the center of the padded image, taking into account the face direction
    if (faceDirection == FaceDirection.straight) {
      for (int i = 0; i < numRows; i++) {
        for (int j = 0; j < (paddedNumCols - 2); j++) {
          paddedImage[i + 1][j + 1] =
              image[i][j + (removeSideColumns / 2).round()];
        }
      }
      // If the face is facing left, we only take the right side of the face image
    } else if (faceDirection == FaceDirection.left) {
      for (int i = 0; i < numRows; i++) {
        for (int j = 0; j < (paddedNumCols - 2); j++) {
          paddedImage[i + 1][j + 1] = image[i][j + removeSideColumns];
        }
      }
      // If the face is facing right, we only take the left side of the face image
    } else if (faceDirection == FaceDirection.right) {
      for (int i = 0; i < numRows; i++) {
        for (int j = 0; j < (paddedNumCols - 2); j++) {
          paddedImage[i + 1][j + 1] = image[i][j];
        }
      }
    }

    // Reflect padding
    // Top and bottom rows
    for (int j = 1; j <= (paddedNumCols - 2); j++) {
      paddedImage[0][j] = paddedImage[2][j]; // Top row
      paddedImage[numRows + 1][j] = paddedImage[numRows - 1][j]; // Bottom row
    }
    // Left and right columns
    for (int i = 0; i < numRows + 2; i++) {
      paddedImage[i][0] = paddedImage[i][2]; // Left column
      paddedImage[i][paddedNumCols - 1] =
          paddedImage[i][paddedNumCols - 3]; // Right column
    }

    return paddedImage;
  }

  static List<List<int>> _applyLaplacian(
    List<List<int>> image, {
    FaceDirection faceDirection = FaceDirection.straight,
  }) {
    final List<List<int>> paddedImage =
        _padImage(image, faceDirection: faceDirection);
    final int numRows = paddedImage.length - 2;
    final int numCols = paddedImage[0].length - 2;
    final List<List<int>> outputImage = List.generate(
      numRows,
      (i) => List.generate(numCols, (j) => 0, growable: false),
      growable: false,
    );

    // Define the Laplacian kernel
    final List<List<int>> kernel = [
      [0, 1, 0],
      [1, -4, 1],
      [0, 1, 0],
    ];

    // Apply the kernel to each pixel
    for (int i = 0; i < numRows; i++) {
      for (int j = 0; j < numCols; j++) {
        int sum = 0;
        for (int ki = 0; ki < 3; ki++) {
          for (int kj = 0; kj < 3; kj++) {
            sum += paddedImage[i + ki][j + kj] * kernel[ki][kj];
          }
        }
        // Adjust the output value if necessary (e.g., clipping)
        outputImage[i][j] = sum; //.clamp(0, 255);
      }
    }

    return outputImage;
  }
}
