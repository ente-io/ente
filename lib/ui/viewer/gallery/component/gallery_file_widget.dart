import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:media_extension/media_extension.dart";
import "package:media_extension/media_extension_action_types.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/services/app_lifecycle_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/navigation_util.dart";

class GalleryFileWidget extends StatelessWidget {
  final File file;
  final SelectedFiles? selectedFiles;
  final bool limitSelectionToOne;
  final String tag;
  final int photoGridSize;
  final int? currentUserID;
  final List<File> filesInGroup;
  final GalleryLoader asyncLoader;
  const GalleryFileWidget({
    required this.file,
    required this.selectedFiles,
    required this.limitSelectionToOne,
    required this.tag,
    required this.photoGridSize,
    required this.currentUserID,
    required this.filesInGroup,
    required this.asyncLoader,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isFileSelected = selectedFiles?.isFileSelected(file) ?? false;
    Color selectionColor = Colors.white;
    if (isFileSelected && file.isUploaded && file.ownerID != currentUserID) {
      final avatarColors = getEnteColorScheme(context).avatarColors;
      selectionColor =
          avatarColors[(file.ownerID!).remainder(avatarColors.length)];
    }
    return GestureDetector(
      onTap: () {
        limitSelectionToOne
            ? _onTapWithSelectionLimit(file)
            : _onTapNoSelectionLimit(context, file);
      },
      onLongPress: () {
        limitSelectionToOne
            ? _onLongPressWithSelectionLimit(context, file)
            : _onLongPressNoSelectionLimit(context, file);
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: Hero(
              tag: tag + file.tag,
              child: isFileSelected
                  ? ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(
                          0.4,
                        ),
                        BlendMode.darken,
                      ),
                      child: ThumbnailWidget(
                        file,
                        diskLoadDeferDuration: thumbnailDiskLoadDeferDuration,
                        serverLoadDeferDuration:
                            thumbnailServerLoadDeferDuration,
                        shouldShowLivePhotoOverlay: true,
                        key: Key(tag + file.tag),
                        thumbnailSize: photoGridSize < photoGridSizeDefault
                            ? thumbnailLargeSize
                            : thumbnailSmallSize,
                        shouldShowOwnerAvatar: !isFileSelected,
                      ),
                    )
                  : ThumbnailWidget(
                      file,
                      diskLoadDeferDuration: thumbnailDiskLoadDeferDuration,
                      serverLoadDeferDuration: thumbnailServerLoadDeferDuration,
                      shouldShowLivePhotoOverlay: true,
                      key: Key(tag + file.tag),
                      thumbnailSize: photoGridSize < photoGridSizeDefault
                          ? thumbnailLargeSize
                          : thumbnailSmallSize,
                      shouldShowOwnerAvatar: !isFileSelected,
                    ),
            ),
          ),
          isFileSelected
              ? Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: selectionColor, //same for both themes
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  void _toggleFileSelection(File file) {
    selectedFiles!.toggleSelection(file);
  }

  void _onTapWithSelectionLimit(File file) {
    if (selectedFiles!.files.isNotEmpty && selectedFiles!.files.first != file) {
      selectedFiles!.clearAll();
    }
    _toggleFileSelection(file);
  }

  void _onTapNoSelectionLimit(BuildContext context, File file) async {
    if (selectedFiles?.files.isNotEmpty ?? false) {
      _toggleFileSelection(file);
    } else {
      if (AppLifecycleService.instance.mediaExtensionAction.action ==
          IntentAction.pick) {
        final ioFile = await getFile(file);
        MediaExtension().setResult("file://${ioFile!.path}");
      } else {
        _routeToDetailPage(file, context);
      }
    }
  }

  void _onLongPressNoSelectionLimit(BuildContext context, File file) {
    if (selectedFiles!.files.isNotEmpty) {
      _routeToDetailPage(file, context);
    } else if (AppLifecycleService.instance.mediaExtensionAction.action ==
        IntentAction.main) {
      HapticFeedback.lightImpact();
      _toggleFileSelection(file);
    }
  }

  Future<void> _onLongPressWithSelectionLimit(
    BuildContext context,
    File file,
  ) async {
    if (AppLifecycleService.instance.mediaExtensionAction.action ==
        IntentAction.pick) {
      final ioFile = await getFile(file);
      MediaExtension().setResult("file://${ioFile!.path}");
    } else {
      _routeToDetailPage(file, context);
    }
  }

  void _routeToDetailPage(File file, BuildContext context) {
    final page = DetailPage(
      DetailPageConfiguration(
        List.unmodifiable(filesInGroup),
        asyncLoader,
        filesInGroup.indexOf(file),
        tag,
      ),
    );
    routeToPage(context, page, forceCustomPageRoute: true);
  }
}
