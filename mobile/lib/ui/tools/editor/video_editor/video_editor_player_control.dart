import "package:flutter/material.dart";
import "package:photos/ente_theme_data.dart";
import "package:video_editor/video_editor.dart";

class VideoEditorPlayerControl extends StatelessWidget {
  const VideoEditorPlayerControl({
    super.key,
    required this.controller,
  });

  final VideoEditorController controller;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "video_editor_player_control",
      child: AnimatedBuilder(
        animation: Listenable.merge([
          controller,
          controller.video,
        ]),
        builder: (_, __) {
          final duration = controller.trimmedDuration;
          final pos = Duration(
            seconds: (controller.videoPosition.inSeconds -
                controller.startTrim.inSeconds),
          );
          final isPlaying = controller.isPlaying;

          return GestureDetector(
            onTap: () {
              if (controller.isPlaying) {
                controller.video.pause();
              } else {
                controller.video.play();
              }
            },
            child: Container(
              height: 28,
              margin: const EdgeInsets.only(top: 24, bottom: 28),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.videoPlayerBackgroundColor,
                borderRadius: BorderRadius.circular(56),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    !isPlaying ? Icons.play_arrow : Icons.pause,
                    size: 21,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${formatter(pos)} / ${formatter(duration)}",
                    // ignore: prefer_const_constructors
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0'),
      ].join(":");
}
