import "dart:async";

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import "package:photos/image/in_memory_image_cache.dart";
import "package:photos/image/provider/local_thumbnail_img.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/ui/viewer/file/file_icons_widget.dart';
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:photos/ui/viewer/gallery/state/gallery_context_state.dart";
import "package:photos/utils/standalone/task_queue.dart";
import 'package:photos/utils/thumbnail_util.dart';

class ThumbnailWidget extends StatefulWidget {
  final EnteFile file;
  final BoxFit fit;

  /// Returns ThumbnailWidget without any overlay icons if true.
  final bool rawThumbnail;
  final bool shouldShowSyncStatus;
  final bool shouldShowArchiveStatus;
  final bool shouldShowPinIcon;
  final bool showFavForAlbumOnly;
  final bool shouldShowLivePhotoOverlay;
  final Duration? diskLoadDeferDuration;
  final Duration? serverLoadDeferDuration;
  final int thumbnailSize;
  final bool shouldShowOwnerAvatar;
  final bool shouldShowFavoriteIcon;

  ///On video thumbnails, shows the video duration if true. If false,
  ///shows a centered play icon.
  final bool shouldShowVideoDuration;
  final bool shouldShowVideoOverlayIcon;

  ThumbnailWidget(
    this.file, {
    Key? key,
    this.fit = BoxFit.cover,
    this.rawThumbnail = false,
    this.shouldShowSyncStatus = true,
    this.shouldShowLivePhotoOverlay = false,
    this.shouldShowArchiveStatus = false,
    this.shouldShowPinIcon = false,
    this.showFavForAlbumOnly = false,
    this.shouldShowOwnerAvatar = false,
    this.diskLoadDeferDuration,
    this.serverLoadDeferDuration,
    this.thumbnailSize = thumbnailSmall256,
    this.shouldShowFavoriteIcon = true,
    this.shouldShowVideoDuration = false,
    this.shouldShowVideoOverlayIcon = true,
  }) : super(key: key ?? Key(file.tag));

  @override
  State<ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
  static final _logger = Logger("ThumbnailWidget");
  bool _hasLoadedThumbnail = false;
  bool _isLoadingRemoteThumbnail = false;
  bool _errorLoadingRemoteThumbnail = false;
  ImageProvider? _imageProvider;
  int? optimizedImageHeight;
  int? optimizedImageWidth;
  LocalThumbnailProviderKey? localImageProviderKey;

  @override
  void initState() {
    super.initState();
    assignOptimizedImageDimensions();
  }

  @override
  void dispose() {
    super.dispose();
    Future.delayed(const Duration(milliseconds: 10), () {
      if (!mounted) {
        if (localImageProviderKey != null) {
          LocalThumbnailProvider.cancelRequest(localImageProviderKey!);
        }
      }
      // Cancel request only if the widget has been unmounted
      if (!mounted && widget.file.isRemoteFile && !_hasLoadedThumbnail) {
        removePendingGetThumbnailRequestIfAny(widget.file);
      }
    });
  }

  @override
  void didUpdateWidget(ThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.file.tag != oldWidget.file.tag) {
      _reset();
    }
  }

  static final smallLocalThumbnailQueue = TaskQueue<String>(
    maxConcurrentTasks: 15,
    taskTimeout: const Duration(minutes: 1),
    maxQueueSize: 200,
  );

  static final largeLocalThumbnailQueue = TaskQueue<String>(
    maxConcurrentTasks: 5,
    taskTimeout: const Duration(minutes: 1),
    maxQueueSize: 200,
  );

  ///Assigned dimension will be the size of a grid item. The size will be
  ///assigned to the side which is smaller in dimension.
  void assignOptimizedImageDimensions() {
    if (widget.file.width == 0 || widget.file.height == 0) {
      return;
    }
    if (widget.file.width < widget.file.height) {
      optimizedImageWidth = widget.thumbnailSize;
    } else {
      optimizedImageHeight = widget.thumbnailSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.file.isRemoteFile) {
      _loadNetworkImage();
    } else {
      // todo(neeraj): implement deferred loading implement deferred loading
      final cachedThumb =
          enteImageCache.getThumb(widget.file, widget.thumbnailSize);
      if (cachedThumb != null) {
        _imageProvider = Image.memory(
          cachedThumb,
        ).image;
        _hasLoadedThumbnail = true;
      } else {
        localImageProviderKey = LocalThumbnailProviderKey(
          asset: widget.file.lAsset!,
          height: widget.thumbnailSize,
          width: widget.thumbnailSize,
        );
        _imageProvider = LocalThumbnailProvider(localImageProviderKey!);
        precacheImage(_imageProvider!, context);
      }
    }
    Widget? image;
    if (_imageProvider != null) {
      image = Image(
        image: _imageProvider!,
        fit: widget.fit,
      );
    }
    // todo: [2ndJuly22] pref-review if the content Widget which depends on
    // thumbnail fetch logic should be part of separate stateFull widget.
    // If yes, parent thumbnail widget can be stateless
    Widget? content;
    if (image != null) {
      if (widget.rawThumbnail) {
        return image;
      }
      final List<Widget> contentChildren = [image];
      if (widget.shouldShowFavoriteIcon) {
        if (FavoritesService.instance.isFavoriteCache(
          widget.file,
          checkOnlyAlbum: widget.showFavForAlbumOnly,
        )) {
          contentChildren.add(const FavoriteOverlayIcon());
        }
      }

      if (widget.file.fileType == FileType.video) {
        if (widget.shouldShowVideoDuration) {
          contentChildren
              .add(VideoOverlayDuration(duration: widget.file.durationInSec!));
        } else if (widget.shouldShowVideoOverlayIcon) {
          contentChildren.add(const VideoOverlayIcon());
        }
      } else if (widget.shouldShowLivePhotoOverlay &&
          widget.file.isLiveOrMotionPhoto) {
        contentChildren.add(const LivePhotoOverlayIcon());
      }
      if (widget.shouldShowOwnerAvatar) {
        if (!widget.file.isOwner) {
          final owner = CollectionsService.instance
              .getFileOwner(widget.file.ownerID!, widget.file.collectionID);
          contentChildren.add(
            OwnerAvatarOverlayIcon(owner),
          );
        } else if (widget.file.isCollect) {
          contentChildren.add(
            // Use -1 as userID for enforcing black avatar color
            OwnerAvatarOverlayIcon(
              User(id: -1, email: '', name: widget.file.uploaderName),
            ),
          );
        }
      }
      content = contentChildren.length == 1
          ? contentChildren.first
          : Stack(
              fit: StackFit.expand,
              children: contentChildren,
            );
    }
    final List<Widget> viewChildren = [
      const ThumbnailPlaceHolder(),
      content ?? const SizedBox(),
    ];
    if (widget.shouldShowSyncStatus && !widget.file.isUploaded) {
      viewChildren.add(const UnSyncedIcon());
    }

    if (widget.file.isTrash) {
      viewChildren.add(TrashedFileOverlayText(widget.file));
    } else if (GalleryContextState.of(context)?.type == GroupType.size) {
      viewChildren.add(FileSizeOverlayText(widget.file));
    }
    // todo: Move this icon overlay to the collection widget.
    if (widget.shouldShowArchiveStatus) {
      viewChildren.add(const ArchiveOverlayIcon());
    }
    if (widget.shouldShowPinIcon) {
      viewChildren.add(const PinOverlayIcon());
    }

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: viewChildren,
    );
  }

  void _loadNetworkImage() {
    if (!_hasLoadedThumbnail &&
        !_errorLoadingRemoteThumbnail &&
        !_isLoadingRemoteThumbnail) {
      _isLoadingRemoteThumbnail = true;
      final cachedThumbnail =
          enteImageCache.getThumb(widget.file, thumbnailLarge512);
      if (cachedThumbnail != null) {
        final imageProvider = Image.memory(
          cachedThumbnail,
          cacheHeight: optimizedImageHeight,
          cacheWidth: optimizedImageWidth,
        ).image;
        _cacheAndRender(imageProvider);
        return;
      }

      if (widget.serverLoadDeferDuration != null) {
        Future.delayed(widget.serverLoadDeferDuration!, () {
          if (mounted) {
            _getThumbnailFromServer();
          }
        });
      } else {
        _getThumbnailFromServer();
      }
    }
  }

  void _getThumbnailFromServer() async {
    try {
      final thumbnail = await getThumbnailFromServer(widget.file);
      if (mounted) {
        final imageProvider = Image.memory(
          thumbnail,
          cacheHeight: optimizedImageHeight,
          cacheWidth: optimizedImageWidth,
        ).image;
        _cacheAndRender(imageProvider);
      }
    } catch (e) {
      if (e is RequestCancelledError) {
        if (mounted) {
          _logger.info(
            "Thumbnail request was aborted although it is in view, will retry",
          );
          _reset();
          setState(() {});
        }
      } else {
        _logger.severe("Could not load image " + widget.file.toString(), e);
        _errorLoadingRemoteThumbnail = true;
      }
    }
  }

  void _cacheAndRender(ImageProvider<Object> imageProvider) {
    if (mounted) {
      setState(() {
        _imageProvider = imageProvider;
        _hasLoadedThumbnail = true;
      });
    }

    precacheImage(imageProvider, context);
  }

  void _reset() {
    _hasLoadedThumbnail = false;
    _isLoadingRemoteThumbnail = false;
    _errorLoadingRemoteThumbnail = false;
    _imageProvider = null;
  }
}
