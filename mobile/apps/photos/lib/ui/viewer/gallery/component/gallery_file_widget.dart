import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:media_extension/media_extension.dart";
import "package:media_extension/media_extension_action_types.dart";
import "package:photos/core/constants.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/selected_files.dart";
import "package:photos/services/app_lifecycle_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/touch_cross_detector.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/state/gallery_context_state.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/gallery_swipe_helper.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/navigation_util.dart";

class GalleryFileWidget extends StatefulWidget {
  final EnteFile file;
  final SelectedFiles? selectedFiles;
  final bool limitSelectionToOne;
  final String tag;
  final int photoGridSize;
  final int? currentUserID;
  const GalleryFileWidget({
    required this.file,
    required this.selectedFiles,
    required this.limitSelectionToOne,
    required this.tag,
    required this.photoGridSize,
    required this.currentUserID,
    super.key,
  });

  @override
  State<GalleryFileWidget> createState() => _GalleryFileWidgetState();
}

class _GalleryFileWidgetState extends State<GalleryFileWidget> {
  static const borderRadius = BorderRadius.all(Radius.circular(1));
  late bool _isFileSelected;
  int? _currentPointerId;
  bool _isPointerInside = false;

  @override
  void initState() {
    super.initState();
    _isFileSelected =
        widget.selectedFiles?.isFileSelected(widget.file) ?? false;
    widget.selectedFiles?.addListener(_selectedFilesListener);
    // Timer.periodic(const Duration(seconds: 2), (_) {
    //   final len = GallerySwipeHelper.of(context)?.allFiles.length;
    //   print("--------- len: $len");
    // });
  }

  @override
  void dispose() {
    widget.selectedFiles?.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swipeHelper = GallerySwipeHelper.of(context);
    Color selectionColor = Colors.white;
    if (_isFileSelected &&
        widget.file.isUploaded &&
        widget.file.ownerID != widget.currentUserID) {
      final avatarColors = getEnteColorScheme(context).avatarColors;
      selectionColor =
          avatarColors[(widget.file.ownerID!).remainder(avatarColors.length)];
    }
    final String heroTag = widget.tag + widget.file.tag;
    final Widget thumbnailWidget = ThumbnailWidget(
      widget.file,
      diskLoadDeferDuration: galleryThumbnailDiskLoadDeferDuration,
      serverLoadDeferDuration: galleryThumbnailServerLoadDeferDuration,
      shouldShowLivePhotoOverlay: true,
      key: Key(heroTag),
      thumbnailSize: widget.photoGridSize < photoGridSizeDefault
          ? thumbnailLargeSize
          : thumbnailSmallSize,
      shouldShowOwnerAvatar: !_isFileSelected,
      shouldShowVideoDuration: true,
    );
    final swipeActiveNotifier =
        GallerySwipeHelper.swipeActiveNotifierOf(context);

    return ValueListenableBuilder<bool>(
      valueListenable: swipeActiveNotifier ?? ValueNotifier(false),
      builder: (context, isSwipeActive, child) {
        // Check if we need to start selection when swipe becomes active
        if (isSwipeActive &&
            _isPointerInside &&
            swipeHelper != null &&
            !swipeHelper.isActive &&
            widget.selectedFiles != null &&
            widget.selectedFiles!.files.isNotEmpty) {
          // Schedule the selection to happen after the current build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                isSwipeActive &&
                _isPointerInside &&
                !swipeHelper.isActive) {
              swipeHelper.startSelection(widget.file);
            }
          });
        }

        return TouchCrossDetector(
          onPointerDown: (event) {
            _currentPointerId = event.pointer;
            _isPointerInside = true;
            // If files are already selected and swipe is not active, prepare for potential swipe
            // The actual selection will start when horizontal movement is detected
          },
          onHover: (event) {
            _isPointerInside = true;
            // Handle the initial file selection when swipe becomes active
            // This is mainly for horizontal swipe detection since vertical after long press
            // is already handled by swipeHelper being active
            if (swipeActiveNotifier?.value == true &&
                swipeHelper != null &&
                !swipeHelper.isActive &&
                widget.selectedFiles != null &&
                widget.selectedFiles!.files.isNotEmpty) {
              // Start selection for the first file when horizontal swipe is detected
              swipeHelper.startSelection(widget.file);
            }
          },
          onEnter: (event) {
            _isPointerInside = true;
            // Check if swipe is active (either from horizontal swipe or from long press)
            if ((swipeActiveNotifier?.value == true ||
                    swipeHelper?.isActive == true) &&
                swipeHelper != null) {
              if (!swipeHelper.isActive) {
                // Start selection when first entering a file during active swipe
                swipeHelper.startSelection(widget.file);
              } else {
                // Update selection for subsequent files
                swipeHelper.updateSelection(widget.file);
              }
            }
          },
          onExit: (event) {
            _isPointerInside = false;
            if (_currentPointerId == event.pointer) {
              _currentPointerId = null;
            }
          },
          child: GestureDetector(
            onTap: () {
              widget.limitSelectionToOne
                  ? _onTapWithSelectionLimit(widget.file)
                  : _onTapNoSelectionLimit(context, widget.file);
            },
            onLongPress: () {
              widget.limitSelectionToOne
                  ? _onLongPressWithSelectionLimit(context, widget.file)
                  : _onLongPressNoSelectionLimit(context, widget.file);
            },
            child: _isFileSelected
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        key: ValueKey(heroTag),
                        borderRadius: borderRadius,
                        child: Hero(
                          tag: heroTag,
                          flightShuttleBuilder: (
                            flightContext,
                            animation,
                            flightDirection,
                            fromHeroContext,
                            toHeroContext,
                          ) =>
                              thumbnailWidget,
                          transitionOnUserGestures: true,
                          child: thumbnailWidget,
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(102, 0, 0, 0),
                          borderRadius: borderRadius,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: selectionColor, //same for both themes
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    key: ValueKey(heroTag),
                    borderRadius: borderRadius,
                    child: Hero(
                      tag: heroTag,
                      flightShuttleBuilder: (
                        flightContext,
                        animation,
                        flightDirection,
                        fromHeroContext,
                        toHeroContext,
                      ) =>
                          thumbnailWidget,
                      transitionOnUserGestures: true,
                      child: thumbnailWidget,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _selectedFilesListener() {
    late bool latestSelectionState;
    if (widget.selectedFiles?.files.contains(widget.file) ?? false) {
      latestSelectionState = true;
    } else {
      latestSelectionState = false;
    }
    if (latestSelectionState != _isFileSelected && mounted) {
      setState(() {
        _isFileSelected = latestSelectionState;
      });
    }
  }

  void _toggleFileSelection(EnteFile file) {
    widget.selectedFiles!.toggleSelection(file);
  }

  void _onTapWithSelectionLimit(EnteFile file) {
    if (widget.selectedFiles!.files.isNotEmpty &&
        widget.selectedFiles!.files.first != file) {
      widget.selectedFiles!.clearAll();
    }
    _toggleFileSelection(file);
  }

  void _onTapNoSelectionLimit(BuildContext context, EnteFile file) async {
    final bool shouldToggleSelection =
        (widget.selectedFiles?.files.isNotEmpty ?? false) ||
            GalleryContextState.of(context)!.inSelectionMode;
    if (shouldToggleSelection) {
      _toggleFileSelection(file);
    } else {
      if (AppLifecycleService.instance.mediaExtensionAction.action ==
          IntentAction.pick) {
        final ioFile = await getFile(file);
        await MediaExtension().setResult("file://${ioFile!.path}");
      } else {
        _routeToDetailPage(file, context);
      }
    }
  }

  void _onLongPressNoSelectionLimit(BuildContext context, EnteFile file) {
    if (widget.selectedFiles!.files.isNotEmpty) {
      _routeToDetailPage(file, context);
    } else {
      HapticFeedback.lightImpact();
      _toggleFileSelection(file);
      // Start swipe selection if pointer is still down after long press
      // Force selecting mode since we just selected this file
      final swipeHelper = GallerySwipeHelper.of(context);
      if (_currentPointerId != null &&
          TouchCrossDetector.isPointerActive(_currentPointerId!) &&
          swipeHelper != null &&
          widget.selectedFiles!.files.isNotEmpty) {
        swipeHelper.startSelection(file, forceSelecting: true);
      }
    }
  }

  Future<void> _onLongPressWithSelectionLimit(
    BuildContext context,
    EnteFile file,
  ) async {
    if (AppLifecycleService.instance.mediaExtensionAction.action ==
        IntentAction.pick) {
      final ioFile = await getFile(file);
      await MediaExtension().setResult("file://${ioFile!.path}");
    } else {
      _routeToDetailPage(file, context);
    }
  }

  void _routeToDetailPage(EnteFile file, BuildContext context) {
    final galleryFiles = GalleryFilesState.of(context).galleryFiles;
    final page = DetailPage(
      DetailPageConfiguration(
        galleryFiles,
        galleryFiles.indexOf(file),
        widget.tag,
      ),
    );
    routeToPage(context, page, forceCustomPageRoute: true);
  }
}
