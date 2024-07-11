import 'package:flutter/material.dart';
import "package:photos/ente_theme_data.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/ui/tools/editor/video_editor/crop_value.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_bottom_action.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_main_actions.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_navigation_options.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_player_control.dart";
import 'package:video_editor/video_editor.dart';

class VideoCropPage extends StatefulWidget {
  const VideoCropPage({super.key, required this.controller});

  final VideoEditorController controller;

  @override
  State<VideoCropPage> createState() => _VideoCropPageState();
}

class _VideoCropPageState extends State<VideoCropPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Hero(
                tag: "video-editor-preview",
                child: CropGridViewer.edit(
                  controller: widget.controller,
                  rotateCropArea: false,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            VideoEditorPlayerControl(
              controller: widget.controller,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 4,
                  child: AnimatedBuilder(
                    animation: widget.controller,
                    builder: (_, __) => Column(
                      children: [
                        VideoEditorMainActions(
                          children: [
                            // _buildCropButton(context, CropValue.original),
                            // const SizedBox(width: 40),
                            _buildCropButton(context, CropValue.free),
                            const SizedBox(width: 40),
                            _buildCropButton(context, CropValue.ratio_1_1),
                            const SizedBox(width: 40),
                            _buildCropButton(
                              context,
                              CropValue.ratio_9_16,
                            ),
                            const SizedBox(width: 40),
                            _buildCropButton(
                              context,
                              CropValue.ratio_16_9,
                            ),
                            const SizedBox(width: 40),
                            _buildCropButton(
                              context,
                              CropValue.ratio_3_4,
                            ),
                            const SizedBox(width: 40),
                            _buildCropButton(
                              context,
                              CropValue.ratio_4_3,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            VideoEditorNavigationOptions(
              color: Theme.of(context).colorScheme.videoPlayerPrimaryColor,
              secondaryText: S.of(context).done,
              onSecondaryPressed: () {
                // WAY 1: validate crop parameters set in the crop view
                widget.controller.applyCacheCrop();
                // WAY 2: update manually with Offset values
                // controller.updateCrop(const Offset(0.2, 0.2), const Offset(0.8, 0.8));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropButton(BuildContext context, CropValue value) {
    final f = value.getFraction();

    return VideoEditorBottomAction(
      label: value.displayName,
      isSelected: value != CropValue.original &&
          widget.controller.preferredCropAspectRatio == f?.toDouble(),
      onPressed: () {
        if (value == CropValue.original) {
          widget.controller.updateCrop(Offset.zero, const Offset(1.0, 1.0));
          widget.controller.cropAspectRatio(null);
          setState(() {});
        } else {
          widget.controller.preferredCropAspectRatio = f?.toDouble();
        }
      },
      svgPath: "assets/video-editor/video-crop-${value.name}-action.svg",
    );
  }
}
