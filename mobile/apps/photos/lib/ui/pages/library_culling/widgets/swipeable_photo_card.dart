import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photos/core/cache/thumbnail_in_memory_cache.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/thumbnail_util.dart';

class SwipeablePhotoCard extends StatefulWidget {
  final EnteFile file;
  final double swipeProgress;
  final bool isSwipingLeft;
  final bool isSwipingRight;

  const SwipeablePhotoCard({
    super.key,
    required this.file,
    this.swipeProgress = 0.0,
    this.isSwipingLeft = false,
    this.isSwipingRight = false,
  });

  @override
  State<SwipeablePhotoCard> createState() => _SwipeablePhotoCardState();
}

class _SwipeablePhotoCardState extends State<SwipeablePhotoCard> {
  ImageProvider? _imageProvider;
  bool _loadingLargeThumbnail = false;
  bool _loadedLargeThumbnail = false;
  bool _loadingFinalImage = false;
  bool _loadedFinalImage = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    // First load thumbnail from cache if available
    final cachedThumbnail = ThumbnailInMemoryLruCache.get(widget.file, thumbnailSmallSize);
    if (cachedThumbnail != null && mounted) {
      setState(() {
        _imageProvider = Image.memory(cachedThumbnail).image;
      });
    }

    // Load large thumbnail
    if (!_loadingLargeThumbnail && !_loadedLargeThumbnail && !_loadedFinalImage) {
      _loadingLargeThumbnail = true;
      
      if (widget.file.isRemoteFile) {
        // For remote files, get thumbnail from server
        getThumbnailFromServer(widget.file).then((file) {
          if (mounted && !_loadedFinalImage) {
            final imageProvider = Image.memory(file).image;
            precacheImage(imageProvider, context).then((_) {
              if (mounted && !_loadedFinalImage) {
                setState(() {
                  _imageProvider = imageProvider;
                  _loadedLargeThumbnail = true;
                });
              }
            });
          }
        });
      } else {
        // For local files, get large thumbnail
        getThumbnailFromLocal(widget.file, size: thumbnailLargeSize, quality: 100)
            .then((thumbnail) {
          if (thumbnail != null && mounted && !_loadedFinalImage) {
            final imageProvider = Image.memory(thumbnail).image;
            precacheImage(imageProvider, context).then((_) {
              if (mounted && !_loadedFinalImage) {
                setState(() {
                  _imageProvider = imageProvider;
                  _loadedLargeThumbnail = true;
                });
              }
            });
          }
        });
      }
    }

    // Load final full-quality image
    if (!_loadingFinalImage && !_loadedFinalImage) {
      _loadingFinalImage = true;
      
      if (widget.file.isRemoteFile) {
        getFileFromServer(widget.file).then((file) {
          if (file != null && mounted) {
            _onFileLoaded(file);
          }
        });
      } else {
        getFile(widget.file).then((file) {
          if (file != null && mounted) {
            _onFileLoaded(file);
          }
        });
      }
    }
  }

  void _onFileLoaded(dynamic file) {
    ImageProvider imageProvider;
    if (file is Uint8List) {
      imageProvider = Image.memory(file).image;
    } else {
      imageProvider = Image.file(file).image;
    }
    
    precacheImage(imageProvider, context).then((_) {
      if (mounted) {
        setState(() {
          _imageProvider = imageProvider;
          _loadedFinalImage = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = getEnteColorScheme(context);
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate border intensity based on swipe progress
    final borderIntensity = (widget.swipeProgress.abs() * 3).clamp(0.0, 1.0);
    final borderWidth = (borderIntensity * 4).clamp(0.0, 4.0); // Thinner border
    
    // Determine border color based on swipe direction
    Color? borderColor;
    
    if (widget.isSwipingLeft) {
      borderColor = theme.warning700.withValues(alpha: borderIntensity);
    } else if (widget.isSwipingRight) {
      borderColor = theme.primary700.withValues(alpha: borderIntensity);
    }

    // Calculate card dimensions to preserve aspect ratio
    final maxWidth = screenSize.width * 0.85;
    final maxHeight = screenSize.height * 0.65;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Main photo - progressively load from thumbnail to full image
            if (_imageProvider != null)
              Image(
                image: _imageProvider!,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              )
            else
              const Center(
                child: EnteLoadingWidget(),
              ),
          
            // Border overlay for swipe feedback
            if (borderColor != null && borderWidth > 0)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}