import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/models/selected_files.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/services/info_file_service.dart";
import "package:locker/ui/components/file_popup_menu_widget.dart";
import "package:locker/ui/components/item_list_view.dart";
import "package:locker/utils/file_icon_utils.dart";
import "package:locker/utils/file_util.dart";
import "package:locker/utils/info_item_utils.dart";

class FileRowWidget extends StatelessWidget {
  final EnteFile file;
  final List<OverflowMenuAction>? overflowActions;
  final bool isLastItem;
  final SelectedFiles? selectedFiles;
  final void Function(EnteFile)? onTapCallback;
  final void Function(EnteFile)? onLongPressCallback;

  const FileRowWidget({
    super.key,
    required this.file,
    this.overflowActions,
    this.isLastItem = false,
    this.selectedFiles,
    this.onTapCallback,
    this.onLongPressCallback,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

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
        } else {
          FileUtil.openFile(context, file);
        }
      },
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
              borderRadius: BorderRadius.circular(20),
              color: colorScheme.backdropBase,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: _buildFileIcon(),
                    ),
                    const SizedBox(width: 12),
                    const Spacer(),
                    FilePopupMenuWidget(
                      file: file,
                      overflowActions: overflowActions,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedMoreVertical,
                        color: colorScheme.textBase,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Spacer(),
                Text(
                  file.displayName,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileIcon() {
    // Check if this is an info file
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

    // For non-info files or if extraction fails, use the original logic
    return FileIconUtils.getFileIcon(file.displayName, showBackground: true);
  }
}
