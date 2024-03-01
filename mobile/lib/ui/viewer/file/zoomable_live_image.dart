import "dart:io";

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:motion_photos/motion_photos.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/services/file_magic_service.dart";
import 'package:photos/ui/viewer/file/zoomable_image.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:video_player/video_player.dart';

class ZoomableLiveImage extends StatefulWidget {
  final EnteFile enteFile;
  final Function(bool)? shouldDisableScroll;
  final String? tagPrefix;
  final Decoration? backgroundDecoration;

  const ZoomableLiveImage(
    this.enteFile, {
    Key? key,
    this.shouldDisableScroll,
    required this.tagPrefix,
    this.backgroundDecoration,
  }) : super(key: key);

  @override
  State<ZoomableLiveImage> createState() => _ZoomableLiveImageState();
}

class _ZoomableLiveImageState extends State<ZoomableLiveImage>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger("ZoomableLiveImage");
  late EnteFile _enteFile;
  bool _showVideo = false;
  bool _isLoadingVideoPlayer = false;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    _enteFile = widget.enteFile;
    _logger.info('initState for ${_enteFile.generatedID} with tag ${_enteFile
        .tag} and name ${_enteFile.displayName}');
    super.initState();
  }

  void _onLongPressEvent(bool isPressed) {
    if (_videoPlayerController != null && isPressed == false) {
      // stop playing video
      _videoPlayerController!.pause();
    }
    if (mounted) {
      setState(() {
        _showVideo = isPressed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    // check is long press is selected but videoPlayer is not configured yet
    if (_showVideo && _videoPlayerController == null) {
      _loadLiveVideo();
    }

    if (_showVideo && _videoPlayerController != null) {
      content = _getVideoPlayer();
    } else {
      content = ZoomableImage(
        _enteFile,
        tagPrefix: widget.tagPrefix,
        shouldDisableScroll: widget.shouldDisableScroll,
        backgroundDecoration: widget.backgroundDecoration,
      );
    }
    return GestureDetector(
      onLongPressStart: (_) => {_onLongPressEvent(true)},
      onLongPressEnd: (_) => {_onLongPressEvent(false)},
      child: content,
    );
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.pause();
      _videoPlayerController!.dispose();
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
    super.dispose();
  }

  Widget _getVideoPlayer() {
    _videoPlayerController!.seekTo(Duration.zero);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      autoPlay: true,
      autoInitialize: true,
      looping: true,
      allowFullScreen: false,
      showControls: false,
    );
    return Container(
      color: Colors.black,
      child: Chewie(controller: _chewieController!), // same for both theme
    );
  }

  Future<void> _loadLiveVideo() async {
    // do nothing is already loading or loaded
    if (_isLoadingVideoPlayer || _videoPlayerController != null) {
      return;
    }
    _isLoadingVideoPlayer = true;
    // For non-live photo, with fileType as Image, we still call _getMotionPhoto
    // to check if it is a motion photo. This is needed to handle earlier
    // uploads and upload from desktop
    final File? videoFile = _enteFile.isLivePhoto
        ? await _getLivePhotoVideo()
        : await _getMotionPhotoVideo();

    if (videoFile != null && videoFile.existsSync()) {
      _setVideoPlayerController(file: videoFile);
    } else if (_enteFile.isLivePhoto) {
      showShortToast(context, S.of(context).downloadFailed);
    }
    _isLoadingVideoPlayer = false;
  }

  Future<File?> _getLivePhotoVideo() async {
    if (_enteFile.isRemoteFile && !(await isFileCached(_enteFile, liveVideo: true))) {
      showShortToast(context, S.of(context).downloading);
    }

    File? videoFile = await getFile(widget.enteFile, liveVideo: true)
        .timeout(const Duration(seconds: 15))
        .onError((dynamic e, s) {
      _logger.info("getFile failed ${_enteFile.tag}", e);
      return null;
    });

    // FixMe: Here, we are fetching video directly when getFile failed
    // getFile with liveVideo as true can fail for file with localID when
    // the live photo was downloaded from remote.
    if ((videoFile == null || !videoFile.existsSync()) &&
        _enteFile.uploadedFileID != null) {
      videoFile = await getFileFromServer(widget.enteFile, liveVideo: true)
          .timeout(const Duration(seconds: 15))
          .onError((dynamic e, s) {
        _logger.info("getRemoteFile failed ${_enteFile.tag}", e);
        return null;
      });
    }
    return videoFile;
  }

  Future<File?> _getMotionPhotoVideo() async {
    if (_enteFile.isRemoteFile && !(await isFileCached(_enteFile))) {
      showShortToast(context, S.of(context).downloading);
    }

    final File? imageFile = await getFile(
      widget.enteFile,
      isOrigin: !Platform.isAndroid,
    ).timeout(const Duration(seconds: 15)).onError((dynamic e, s) {
      _logger.info("getFile failed ${_enteFile.tag}", e);
      return null;
    });
    if (imageFile != null) {
      final motionPhoto = MotionPhotos(imageFile.path);
      final index = await motionPhoto.getMotionVideoIndex();
      if (index != null) {
        // Update the metadata if it is not updated
        if (!_enteFile.isMotionPhoto && _enteFile.canEditMetaInfo) {
          FileMagicService.instance.updatePublicMagicMetadata(
            [_enteFile],
            {motionVideoIndexKey: index.start},
          ).ignore();
        }
        return motionPhoto.getMotionVideoFile(
          index: index,
        );
      }
    }
    return null;
  }

  VideoPlayerController _setVideoPlayerController({required File file}) {
    final videoPlayerController = VideoPlayerController.file(file);
    return _videoPlayerController = videoPlayerController
      ..initialize().whenComplete(() {
        if (mounted) {
          setState(() {
            _showVideo = true;
          });
        }
      });
  }

}
