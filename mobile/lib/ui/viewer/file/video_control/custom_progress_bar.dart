// ignore_for_file: implementation_imports

import "package:chewie/src/chewie_progress_colors.dart";
import "package:chewie/src/progress_bar.dart";
import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:video_player/video_player.dart";

class CustomProgressBar extends StatelessWidget {
  CustomProgressBar(
    this.controller, {
    ChewieProgressColors? colors,
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
    super.key,
    this.draggableProgressBar = true,
  }) : colors = colors ?? ChewieProgressColors();

  final VideoPlayerController controller;
  final ChewieProgressColors colors;
  final Function()? onDragStart;
  final Function()? onDragEnd;
  final Function()? onDragUpdate;
  final bool draggableProgressBar;

  @override
  Widget build(BuildContext context) {
    return VideoProgressBar(
      controller,
      barHeight: 1.5,
      handleHeight: 8,
      drawShadow: true,
      colors: colors,
      onDragEnd: onDragEnd,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      draggableProgressBar: draggableProgressBar,
    );
  }
}
