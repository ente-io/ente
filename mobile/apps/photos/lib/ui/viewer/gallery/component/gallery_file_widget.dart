import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:media_extension/media_extension.dart";
import "package:media_extension/media_extension_action_types.dart";
import "package:photos/core/constants.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/selected_files.dart";
import "package:photos/services/app_lifecycle_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/state/gallery_context_state.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
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

  @override
  void initState() {
    super.initState();
    _isFileSelected =
        widget.selectedFiles?.isFileSelected(widget.file) ?? false;
    widget.selectedFiles?.addListener(_selectedFilesListener);
  }

  @override
  void dispose() {
    widget.selectedFiles?.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    return GestureDetector(
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
