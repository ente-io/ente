import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';

/// A widget that displays a video preview with proper rotation and dimension handling.
///
/// This widget automatically handles dimension swapping for 90° and 270° rotations
/// and applies the necessary rotation transformation.
class RotatedVideoPreview extends StatelessWidget {
  const RotatedVideoPreview({
    super.key,
    required this.controller,
    required this.quarterTurnsForRotationCorrection,
    this.isEditMode = false,
    this.rotateCropArea = false,
    this.margin,
  });

  final VideoEditorController controller;
  final int quarterTurnsForRotationCorrection;
  final bool isEditMode;
  final bool rotateCropArea;
  final EdgeInsets? margin;

  /// Helper method to determine if dimensions should be swapped
  /// Returns true for 90° and 270° rotations (odd quarter turns)
  static bool shouldSwapDimensions(int quarterTurns) {
    return quarterTurns.abs() % 2 == 1;
  }

  /// Helper method to get the correct dimensions based on rotation
  static (double width, double height) getDimensionsForRotation({
    required VideoEditorController controller,
    required int quarterTurns,
  }) {
    final originalWidth = controller.video.value.size.width;
    final originalHeight = controller.video.value.size.height;

    if (shouldSwapDimensions(quarterTurns)) {
      return (originalHeight, originalWidth);
    }
    return (originalWidth, originalHeight);
  }

  @override
  Widget build(BuildContext context) {
    if (quarterTurnsForRotationCorrection == 0) {
      // No rotation needed
      return isEditMode
          ? CropGridViewer.edit(
              controller: controller,
              rotateCropArea: rotateCropArea,
              margin: margin ?? EdgeInsets.zero,
            )
          : CropGridViewer.preview(
              controller: controller,
            );
    }

    // Get dimensions with rotation consideration
    final (width, height) = getDimensionsForRotation(
      controller: controller,
      quarterTurns: quarterTurnsForRotationCorrection,
    );

    return RotatedBox(
      quarterTurns: quarterTurnsForRotationCorrection,
      child: isEditMode
          ? CropGridViewer.edit(
              controller: controller,
              rotateCropArea: rotateCropArea,
              margin: margin ?? EdgeInsets.zero,
              overrideWidth: width,
              overrideHeight: height,
            )
          : CropGridViewer.preview(
              controller: controller,
              overrideWidth: width,
              overrideHeight: height,
            ),
    );
  }
}
