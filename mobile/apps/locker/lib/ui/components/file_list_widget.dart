import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_ui/components/buttons/icon_button_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/models/selected_files.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/configuration.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/services/info_file_service.dart";
import "package:locker/ui/sharing/album_share_info_widget.dart";
import "package:locker/utils/file_icon_utils.dart";
import "package:locker/utils/file_util.dart";
import "package:locker/utils/info_item_utils.dart";

class FileListWidget extends StatelessWidget {
  final EnteFile file;
  final bool isLastItem;
  final SelectedFiles? selectedFiles;
  final void Function(EnteFile)? onTapCallback;
  final void Function(EnteFile)? onLongPressCallback;

  const FileListWidget({
    super.key,
    required this.file,
    this.isLastItem = false,
    this.selectedFiles,
    this.onTapCallback,
    this.onLongPressCallback,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    final collection = file.collectionID != null
        ? CollectionService.instance.getFromCache(file.collectionID!)
        : null;

    final int? currentUserID = Configuration.instance.getUserID();
    final bool isOwner = collection != null &&
        currentUserID != null &&
        collection.isOwner(currentUserID);
    final List<User> sharees =
        collection?.sharees.whereType<User>().toList() ?? const [];
    final bool hasSharees = sharees.isNotEmpty;
    final bool isOutgoing = isOwner && hasSharees;
    final bool isIncoming = collection != null && !isOwner;
    final bool showSharingIndicator = isOutgoing || isIncoming;

    final fileRowWidget = Flexible(
      flex: 6,
      child: Row(
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _buildFileIcon(),
                ),
                if (showSharingIndicator)
                  Positioned(
                    right: 1,
                    bottom: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.backdropBase,
                      ),
                      padding: const EdgeInsets.all(1.0),
                      child: HugeIcon(
                        icon: isOutgoing
                            ? HugeIcons.strokeRoundedCircleArrowUpRight
                            : HugeIcons.strokeRoundedCircleArrowDownLeft,
                        strokeWidth: 2.0,
                        color: colorScheme.primary700,
                        size: 16.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  file.displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        if (onTapCallback != null) {
          onTapCallback!(file);
        } else {
          FileUtil.openFile(context, file);
        }
      },
      onLongPress: () {
        if (onLongPressCallback != null) {
          onLongPressCallback!(file);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: ListenableBuilder(
        listenable: selectedFiles ?? ValueNotifier(false),
        builder: (context, _) {
          final bool isSelected = selectedFiles?.isFileSelected(file) ?? false;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary700
                    : colorScheme.backdropBase,
                width: 1.5,
              ),
              color: colorScheme.backdropBase,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                fileRowWidget,
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: isSelected
                        ? IconButtonWidget(
                            key: const ValueKey("selected"),
                            icon: Icons.check_circle_rounded,
                            iconButtonType: IconButtonType.secondary,
                            iconColor: colorScheme.primary700,
                          )
                        : (showSharingIndicator && hasSharees)
                            ? _buildShareesAvatars(sharees)
                            : const SizedBox(
                                key: ValueKey("unselected"),
                                width: 12,
                              ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileIcon() {
    if (InfoFileService.instance.isInfoFile(file)) {
      try {
        final infoItem = InfoFileService.instance.extractInfoFromFile(file);
        if (infoItem != null) {
          return InfoItemUtils.getInfoIcon(infoItem.type);
        }
      } catch (e) {
        // Fallback to default icon if extraction fails
      }
    }

    return FileIconUtils.getFileIcon(file.displayName, showBackground: true);
  }

  Widget _buildShareesAvatars(List<User> sharees) {
    if (sharees.isEmpty) {
      return const SizedBox.shrink();
    }

    const int limitCountTo = 1;
    const double avatarSize = 24.0;
    const double overlapPadding = 20.0;

    final hasMore = sharees.length > limitCountTo;

    final double totalWidth =
        hasMore ? avatarSize + overlapPadding : avatarSize;

    return SizedBox(
      height: avatarSize,
      width: totalWidth,
      child: AlbumSharesIcons(
        sharees: sharees,
        padding: EdgeInsets.zero,
        limitCountTo: limitCountTo,
        type: AvatarType.mini,
        removeBorder: true,
      ),
    );
  }
}
