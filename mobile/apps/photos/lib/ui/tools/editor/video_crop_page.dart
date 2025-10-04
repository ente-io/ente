import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/tools/editor/video_editor/crop_value.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_app_bar.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_bottom_action.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_main_actions.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_player_control.dart";
import 'package:video_editor/video_editor.dart';

class VideoCropPage extends StatefulWidget {
  final int quarterTurnsForRotationCorrection;
  const VideoCropPage({
    super.key,
    required this.controller,
    required this.quarterTurnsForRotationCorrection,
  });

  final VideoEditorController controller;

  @override
  State<VideoCropPage> createState() => _VideoCropPageState();
}

class _VideoCropPageState extends State<VideoCropPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: VideoEditorAppBar(
        onCancel: () => Navigator.pop(context),
        primaryActionLabel: AppLocalizations.of(context).done,
        onPrimaryAction: () {
          widget.controller.applyCacheCrop();
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Hero(
                          tag: "video-editor-preview",
                          child: Builder(
                            builder: (context) {
                              // For videos with metadata rotation, we need to swap dimensions
                              final shouldSwap =
                                  widget.quarterTurnsForRotationCorrection %
                                          2 ==
                                      1;
                              final width =
                                  widget.controller.video.value.size.width;
                              final height =
                                  widget.controller.video.value.size.height;

                              return RotatedBox(
                                quarterTurns:
                                    widget.quarterTurnsForRotationCorrection,
                                child: CropGridViewer.edit(
                                  controller: widget.controller,
                                  rotateCropArea: false,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  overrideWidth: shouldSwap ? height : width,
                                  overrideHeight: shouldSwap ? width : height,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: VideoEditorPlayerControl(
                            controller: widget.controller,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: widget.controller,
                builder: (_, __) => VideoEditorMainActions(
                  children: [
                    _buildCropButton(context, CropValue.free),
                    const SizedBox(width: 24),
                    _buildCropButton(context, CropValue.ratio_1_1),
                    const SizedBox(width: 24),
                    _buildCropButton(context, CropValue.ratio_9_16),
                    const SizedBox(width: 24),
                    _buildCropButton(context, CropValue.ratio_16_9),
                    const SizedBox(width: 24),
                    _buildCropButton(context, CropValue.ratio_3_4),
                    const SizedBox(width: 24),
                    _buildCropButton(context, CropValue.ratio_4_3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropButton(BuildContext context, CropValue value) {
    final f = value.getFraction();
    // For videos with 90° or 270° rotation, we need to invert the aspect ratio
    // because the crop is applied to the original (pre-rotation) video dimensions
    final shouldSwap = widget.quarterTurnsForRotationCorrection % 2 == 1;
    final aspectRatio = f?.toDouble();
    final adjustedRatio =
        (shouldSwap && aspectRatio != null) ? (1.0 / aspectRatio) : aspectRatio;

    return VideoEditorBottomAction(
      label: value.displayName,
      isSelected: value != CropValue.original &&
          widget.controller.preferredCropAspectRatio == adjustedRatio,
      onPressed: () {
        if (value == CropValue.original) {
          widget.controller.updateCrop(Offset.zero, const Offset(1.0, 1.0));
          widget.controller.cropAspectRatio(null);
          setState(() {});
        } else {
          widget.controller.preferredCropAspectRatio = adjustedRatio;
        }
      },
      svgPath: "assets/video-editor/video-crop-${value.name}-action.svg",
    );
  }
}
