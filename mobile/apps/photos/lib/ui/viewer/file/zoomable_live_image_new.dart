import "dart:async";
import "dart:io";

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import "package:media_kit/media_kit.dart";
import "package:media_kit_video/media_kit_video.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/guest_view_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/services/file_magic_service.dart";
import "package:photos/src/rust/api/motion_photo_api.dart";
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/viewer/file/zoomable_image.dart';
import 'package:photos/utils/file_util.dart';

class ZoomableLiveImageNew extends StatefulWidget {
  final EnteFile enteFile;
  final Function(bool)? shouldDisableScroll;
  final String? tagPrefix;
  final Decoration? backgroundDecoration;
  final bool isFromMemories;
  final Function({required int memoryDuration})? onFinalFileLoad;

  const ZoomableLiveImageNew(
    this.enteFile, {
    super.key,
    this.shouldDisableScroll,
    required this.tagPrefix,
    this.backgroundDecoration,
    this.isFromMemories = false,
    this.onFinalFileLoad,
  });

  @override
  State<ZoomableLiveImageNew> createState() => _ZoomableLiveImageNewState();
}

class _ZoomableLiveImageNewState extends State<ZoomableLiveImageNew>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger("ZoomableLiveImageNew");
  late EnteFile _enteFile;
  bool _showVideo = false;
  bool _isLoadingVideoPlayer = false;
  bool _isVideoFrameReady = true;

  late final _player = Player();
  VideoController? _videoController;

  bool isGuestView = false;
  late final StreamSubscription<GuestViewEvent> _guestViewEventSubscription;

  @override
  void initState() {
    super.initState();

    _enteFile = widget.enteFile;
    _logger.info(
      'initState for ${_enteFile.generatedID} with tag ${_enteFile.tag} and name ${_enteFile.displayName}',
    );
    _guestViewEventSubscription =
        Bus.instance.on<GuestViewEvent>().listen((event) {
      setState(() {
        isGuestView = event.isGuestView;
      });
    });
  }

  void _onLongPressEvent(bool isPressed) {
    if (isPressed) {
      if (_videoController == null) {
        unawaited(_loadLiveVideo());
      } else {
        _videoController!.player.seek(Duration.zero).ignore();
        _videoController!.player.play().ignore();
      }
    } else if (_videoController != null) {
      // stop playing video
      _videoController!.player.pause().ignore();
    }
    if (mounted) {
      setState(() {
        _showVideo = isPressed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = ZoomableImage(
      _enteFile,
      tagPrefix: widget.tagPrefix,
      shouldDisableScroll: widget.shouldDisableScroll,
      backgroundDecoration: widget.backgroundDecoration,
      isGuestView: isGuestView,
      onFinalFileLoad: widget.onFinalFileLoad,
    );

    final shouldShowVideo =
        _showVideo && _videoController != null && _isVideoFrameReady;

    final Widget content = Stack(
      fit: StackFit.expand,
      children: [
        image,
        if (_videoController != null)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            opacity: shouldShowVideo ? 1 : 0,
            child: IgnorePointer(
              ignoring: !shouldShowVideo,
              child: _getVideoPlayer(),
            ),
          ),
      ],
    );

    if (!widget.isFromMemories) {
      return GestureDetector(
        onLongPressStart: (_) => _onLongPressEvent(true),
        onLongPressEnd: (_) => _onLongPressEvent(false),
        child: content,
      );
    }
    return content;
  }

  @override
  void dispose() {
    if (_videoController != null) {
      _videoController!.player.stop();
      _videoController!.player.dispose();
    }
    _guestViewEventSubscription.cancel();
    super.dispose();
  }

  Widget _getVideoPlayer() {
    return Container(
      color: Colors.black,
      child: Video(
        controller: _videoController!,
        controls: null,
      ),
    );
  }

  Future<void> _loadLiveVideo() async {
    // do nothing is already loading or loaded
    if (_isLoadingVideoPlayer || _videoController != null) {
      return;
    }
    _isLoadingVideoPlayer = true;
    try {
      // For non-live photo, with fileType as Image, we still call _getMotionPhoto
      // to check if it is a motion photo. This is needed to handle earlier
      // uploads and upload from desktop
      final File? videoFile = _enteFile.isLivePhoto
          ? await _getLivePhotoVideo()
          : await _getMotionPhotoVideo();

      if (videoFile != null && videoFile.existsSync()) {
        await _setVideoController(videoFile.path);
      } else if (_enteFile.isLivePhoto) {
        showShortToast(context, AppLocalizations.of(context).downloadFailed);
      }
    } finally {
      _isLoadingVideoPlayer = false;
    }
  }

  Future<File?> _getLivePhotoVideo() async {
    if (_enteFile.isRemoteFile &&
        !(await isFileCached(_enteFile, liveVideo: true))) {
      showShortToast(context, AppLocalizations.of(context).downloading);
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
      showShortToast(context, AppLocalizations.of(context).downloading);
    }

    final File? imageFile = await getFile(
      widget.enteFile,
      isOrigin: !Platform.isAndroid,
    ).timeout(const Duration(seconds: 15)).onError((dynamic e, s) {
      _logger.info("getFile failed ${_enteFile.tag}", e);
      return null;
    });
    if (imageFile != null) {
      final index = await getMotionVideoIndex(filePath: imageFile.path);
      if (index != null) {
        // Update the metadata if it is not updated
        if (!_enteFile.isMotionPhoto && _enteFile.canEditMetaInfo) {
          FileMagicService.instance.updatePublicMagicMetadata(
            [_enteFile],
            {motionVideoIndexKey: index.start.toInt()},
          ).ignore();
        }
        final outputPath = await extractMotionVideoFile(
          filePath: imageFile.path,
          destinationDirectory: (await getTemporaryDirectory()).path,
          index: index,
        );
        if (outputPath != null) {
          return File(outputPath);
        }
      } else if (_enteFile.isMotionPhoto && _enteFile.canEditMetaInfo) {
        _logger.info('Incorrectly tagged as MP, reset tag ${_enteFile.tag}');
        FileMagicService.instance.updatePublicMagicMetadata(
          [_enteFile],
          {motionVideoIndexKey: 0},
        ).ignore();
      }
    }
    return null;
  }

  Future<void> _setVideoController(String url) async {
    if (!mounted) return;

    final controller = VideoController(_player);
    setState(() {
      _videoController = controller;
      _isVideoFrameReady = false;
    });

    try {
      await _player.setPlaylistMode(PlaylistMode.single);
      await _player.open(Media(url), play: true);
    } catch (e, s) {
      _logger.info(
        "Failed to initialize live photo video ${_enteFile.tag}",
        e,
        s,
      );
      if (!mounted || _videoController != controller) return;
      setState(() {
        _videoController = null;
        _isVideoFrameReady = false;
      });
      return;
    }

    // If long-press has already ended by this point, don't keep playback running.
    if (!_showVideo) {
      await _player.pause();
    }

    try {
      await controller.waitUntilFirstFrameRendered
          .timeout(const Duration(seconds: 2));
    } catch (e, s) {
      _logger.info("First frame wait failed for ${_enteFile.tag}", e, s);
    }

    if (_showVideo) {
      await _player.seek(Duration.zero);
      await _player.play();
    }

    if (!mounted || _videoController != controller) return;
    setState(() {
      _isVideoFrameReady = true;
    });
  }
}
