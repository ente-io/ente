// ignore_for_file: unused_import

import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/service_locator.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/viewer/file/preview_video_widget.dart";
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/video_controls.dart';
import "package:photos/ui/viewer/file/video_widget.dart";
import "package:photos/utils/dialog_util.dart";
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/toast_util.dart';
import "package:photos/utils/wakelock_util.dart";
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoViewWidget extends StatefulWidget {
  final EnteFile file;
  final bool? autoPlay;
  final String? tagPrefix;
  final Function(bool)? playbackCallback;

  const VideoViewWidget(
    this.file, {
    this.autoPlay = false,
    this.tagPrefix,
    this.playbackCallback,
    super.key,
  });

  @override
  State<VideoViewWidget> createState() => _VideoViewWidgetState();
}

class _VideoViewWidgetState extends State<VideoViewWidget> {
  final _logger = Logger("VideoViewWidget");
  bool isCheckingForPreview = true;
  File? previewFile;

  @override
  void initState() {
    super.initState();
    _checkForPreview();
  }

  void _checkForPreview() {
    if (!flagService.internalUser) return;
    getPreviewFileFromServer(
      widget.file,
    ).then((file) {
      if (!mounted) return;
      if (file != null) {
        isCheckingForPreview = false;
        previewFile = file;
        setState(() {});
      } else {
        isCheckingForPreview = false;
        setState(() {});
      }
    }).onError((error, stackTrace) {
      if (!mounted) return;
      _logger.warning("Failed to download preview video", error, stackTrace);
      showErrorDialog(
        context,
        "Error",
        S.of(context).failedToDownloadVideo,
      );
      isCheckingForPreview = false;
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (flagService.internalUser) {
      if (isCheckingForPreview) {
        return _getLoadingWidget();
      }

      if (previewFile != null) {
        return PreviewVideoWidget(
          widget.file,
          tagPrefix: widget.tagPrefix,
          playbackCallback: widget.playbackCallback,
        );
      }
    }

    if (kDebugMode && Platform.isIOS) {
      return VideoWidget(
        widget.file,
        tagPrefix: widget.tagPrefix,
        playbackCallback: widget.playbackCallback,
      );
    }
    return VideoWidget(
      widget.file,
      tagPrefix: widget.tagPrefix,
      playbackCallback: widget.playbackCallback,
    );
  }

  Widget _getLoadingWidget() {
    return Stack(
      children: [
        _getThumbnail(),
        Container(
          color: Colors.black12,
          constraints: const BoxConstraints.expand(),
        ),
        Center(
          child: SizedBox.fromSize(
            size: const Size.square(20),
            child: const CupertinoActivityIndicator(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _getThumbnail() {
    return Container(
      color: Colors.black,
      constraints: const BoxConstraints.expand(),
      child: ThumbnailWidget(
        widget.file,
        fit: BoxFit.contain,
      ),
    );
  }
}
