import 'package:flutter/material.dart';
import "package:photos/ente_theme_data.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_bottom_action.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_main_actions.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_navigation_options.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_player_control.dart";
import 'package:video_editor/video_editor.dart';

class VideoRotatePage extends StatefulWidget {
  final int quarterTurnsForRotationCorrection;
  const VideoRotatePage({
    super.key,
    required this.controller,
    required this.quarterTurnsForRotationCorrection,
  });

  final VideoEditorController controller;

  @override
  State<VideoRotatePage> createState() => _VideoRotatePageState();
}

class _VideoRotatePageState extends State<VideoRotatePage> {
  @override
  Widget build(BuildContext context) {
    final initialRotation = widget.controller.rotation;
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
                child: Builder(
                  builder: (context) {
                    // For videos with metadata rotation, we need to swap dimensions
                    final shouldSwap = widget.quarterTurnsForRotationCorrection % 2 == 1;
                    final width = widget.controller.video.value.size.width;
                    final height = widget.controller.video.value.size.height;

                    return RotatedBox(
                      quarterTurns: widget.quarterTurnsForRotationCorrection,
                      child: CropGridViewer.preview(
                        controller: widget.controller,
                        overrideWidth: shouldSwap ? height : width,
                        overrideHeight: shouldSwap ? width : height,
                      ),
                    );
                  },
                ),
              ),
            ),
            VideoEditorPlayerControl(
              controller: widget.controller,
            ),
            VideoEditorMainActions(
              children: [
                VideoEditorBottomAction(
                  label: AppLocalizations.of(context).left,
                  onPressed: () {
                    widget.controller.rotate90Degrees(RotateDirection.left);
                    setState(() {});
                  },
                  icon: Icons.rotate_left,
                ),
                const SizedBox(width: 40),
                VideoEditorBottomAction(
                  label: AppLocalizations.of(context).right,
                  onPressed: () {
                    widget.controller.rotate90Degrees(RotateDirection.right);
                    setState(() {});
                  },
                  icon: Icons.rotate_right,
                ),
              ],
            ),
            const SizedBox(height: 40),
            VideoEditorNavigationOptions(
              color: Theme.of(context).colorScheme.videoPlayerPrimaryColor,
              secondaryText: AppLocalizations.of(context).done,
              onPrimaryPressed: () {
                while (widget.controller.rotation != initialRotation) {
                  widget.controller.rotate90Degrees(RotateDirection.left);
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
