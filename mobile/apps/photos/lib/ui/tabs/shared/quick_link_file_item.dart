import "package:flutter/material.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/api/file_share_url.dart";
import "package:photos/models/file/file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class QuickLinkFileItem extends StatelessWidget {
  final FileShareUrl fileShareUrl;
  final List<FileShareUrl> selectedFileShares;
  final VoidCallback? onShareTap;

  const QuickLinkFileItem({
    super.key,
    required this.fileShareUrl,
    this.selectedFileShares = const [],
    this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedFileShares.contains(fileShareUrl);
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return AnimatedContainer(
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              isSelected ? colorScheme.strokeMuted : colorScheme.strokeFainter,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(6),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 6,
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: FutureBuilder<EnteFile?>(
                    future: FilesDB.instance
                        .getAnyUploadedFile(fileShareUrl.fileID),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: ThumbnailWidget(snapshot.data!),
                        );
                      } else {
                        return const NoThumbnailWidget();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<EnteFile?>(
                          future: FilesDB.instance
                              .getAnyUploadedFile(fileShareUrl.fileID),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Text(
                                snapshot.data!.displayName,
                                overflow: TextOverflow.ellipsis,
                              );
                            } else {
                              return const EnteLoadingWidget(size: 12);
                            }
                          },
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              "1  \u2022  ",
                              style: textTheme.smallMuted,
                            ),
                            fileShareUrl.isExpired
                                ? Icon(
                                    Icons.link_outlined,
                                    color: colorScheme.warning500,
                                    size: 22,
                                  )
                                : Icon(
                                    Icons.link_outlined,
                                    color: colorScheme.strokeMuted,
                                    size: 22,
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isSelected
                  ? IconButtonWidget(
                      key: const ValueKey("selected"),
                      icon: Icons.check_circle_rounded,
                      iconButtonType: IconButtonType.secondary,
                      iconColor: colorScheme.blurStrokeBase,
                    )
                  : GestureDetector(
                      onTap: onShareTap,
                      child: IconButtonWidget(
                        key: const ValueKey("share"),
                        icon: Icons.adaptive.share,
                        iconButtonType: IconButtonType.secondary,
                        iconColor: colorScheme.blurStrokePressed,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
