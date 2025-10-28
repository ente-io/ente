import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:native_video_editor/native_video_editor.dart';
import 'package:video_editor/video_editor.dart';

/// A wrapper widget that properly handles video preview with rotation correction
/// on Android, maintaining the correct aspect ratio.
class NativeVideoPreview extends StatefulWidget {
  final VideoEditorController controller;
  final int? quarterTurnsForRotationCorrection;

  const NativeVideoPreview({
    Key? key,
    required this.controller,
    this.quarterTurnsForRotationCorrection,
  }) : super(key: key);

  @override
  State<NativeVideoPreview> createState() => _NativeVideoPreviewState();
}

class _NativeVideoPreviewState extends State<NativeVideoPreview> {
  final _logger = Logger('NativeVideoPreview');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideoInfo();
  }

  Future<void> _loadVideoInfo() async {
    if (Platform.isAndroid) {
      try {
        // Validate rotation metadata from native code
        // This ensures the rotation correction is needed
        final videoPath = widget.controller.file.path;
        final videoInfo = await NativeVideoEditor.getVideoInfo(videoPath);

        final rotation = videoInfo['rotation'] as int? ?? 0;
        final needsDimensionSwap = rotation == 90 ||
            rotation == 270 ||
            rotation == -90 ||
            rotation == -270;

        _logger.info(
          'NativeVideoPreview - Video info from native: '
          'width=${videoInfo['width']}, height=${videoInfo['height']}, '
          'rotation=${videoInfo['rotation']} '
          '${needsDimensionSwap ? "(dimensions swapped for display due to rotation)" : ""}',
        );
        _logger.info(
          'NativeVideoPreview - Controller video: '
          'width=${widget.controller.video.value.size.width}, '
          'height=${widget.controller.video.value.size.height}',
        );
        _logger.info(
          'NativeVideoPreview - quarterTurnsForRotationCorrection=${widget.quarterTurnsForRotationCorrection}',
        );

        // The controller already has the correct aspect ratio from FFProbeProps
        // which handles rotation internally. We only apply visual rotation correction.

        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        // Failed to get video info, fallback to default behavior
        _logger.warning('Failed to get video info: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quarterTurnsForRotationCorrection != null &&
        widget.quarterTurnsForRotationCorrection != 0) {
      final controllerWidth = widget.controller.video.value.size.width;
      final controllerHeight = widget.controller.video.value.size.height;

      final displayWidth = controllerHeight;
      final displayHeight = controllerWidth;

      _logger.info(
        'NativeVideoPreview build - '
        'quarterTurns=${widget.quarterTurnsForRotationCorrection}, '
        'Controller: ${controllerWidth}x${controllerHeight}, '
        'Display: ${displayWidth}x${displayHeight}',
      );

      return RotatedBox(
        quarterTurns: widget.quarterTurnsForRotationCorrection!,
        child: CropGridViewer.preview(
          controller: widget.controller,
          overrideWidth: displayWidth,
          overrideHeight: displayHeight,
        ),
      );
    }
    return CropGridViewer.preview(controller: widget.controller);
  }
}
