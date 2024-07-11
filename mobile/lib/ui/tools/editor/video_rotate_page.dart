import 'package:flutter/material.dart';
import "package:photos/ente_theme_data.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_bottom_action.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_main_actions.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_navigation_options.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_player_control.dart";
import 'package:video_editor/video_editor.dart';

class VideoRotatePage extends StatelessWidget {
  const VideoRotatePage({super.key, required this.controller});

  final VideoEditorController controller;

  @override
  Widget build(BuildContext context) {
    final rotation = controller.rotation;
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
                child: CropGridViewer.preview(
                  controller: controller,
                ),
              ),
            ),
            VideoEditorPlayerControl(
              controller: controller,
            ),
            VideoEditorMainActions(
              children: [
                VideoEditorBottomAction(
                  label: S.of(context).left,
                  onPressed: () =>
                      controller.rotate90Degrees(RotateDirection.left),
                  icon: Icons.rotate_left,
                ),
                const SizedBox(width: 40),
                VideoEditorBottomAction(
                  label: S.of(context).right,
                  onPressed: () =>
                      controller.rotate90Degrees(RotateDirection.right),
                  icon: Icons.rotate_right,
                ),
              ],
            ),
            const SizedBox(height: 40),
            VideoEditorNavigationOptions(
              color: Theme.of(context).colorScheme.videoPlayerPrimaryColor,
              secondaryText: S.of(context).done,
              onPrimaryPressed: () {
                while (controller.rotation != rotation) {
                  controller.rotate90Degrees(RotateDirection.left);
                }
                Navigator.pop(context);
              },
              onSecondaryPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
