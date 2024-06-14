import 'package:flutter/material.dart';
import "package:photos/ente_theme_data.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_navigation_options.dart";
import "package:photos/ui/tools/editor/video_editor/video_editor_player_control.dart";
import 'package:video_editor/video_editor.dart';

class VideoTrimPage extends StatefulWidget {
  const VideoTrimPage({super.key, required this.controller});

  final VideoEditorController controller;

  @override
  State<VideoTrimPage> createState() => _VideoTrimPageState();
}

class _VideoTrimPageState extends State<VideoTrimPage> {
  final double height = 60;

  @override
  Widget build(BuildContext context) {
    final minTrim = widget.controller.minTrim;
    final maxTrim = widget.controller.maxTrim;

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
                  controller: widget.controller,
                ),
              ),
            ),
            VideoEditorPlayerControl(
              controller: widget.controller,
            ),
            ..._trimSlider(),
            const SizedBox(height: 40),
            VideoEditorNavigationOptions(
              color: Theme.of(context).colorScheme.videoPlayerPrimaryColor,
              secondaryText: S.of(context).done,
              onPrimaryPressed: () {
                // reset trim
                widget.controller.updateTrim(minTrim, maxTrim);
                Navigator.pop(context);
              },
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

  List<Widget> _trimSlider() {
    return [
      Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(vertical: height / 4, horizontal: 20),
        child: TrimSlider(
          controller: widget.controller,
          height: height,
          horizontalMargin: height / 4,
        ),
      ),
    ];
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0'),
      ].join(":");
}
