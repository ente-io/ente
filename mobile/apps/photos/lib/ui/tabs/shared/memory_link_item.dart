import "package:flutter/material.dart";
import "package:photos/db/files_db.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class MemoryLinkAlbumItem extends StatelessWidget {
  static const heroTagPrefix = "memory_link";
  final String title;
  final int? fileCount;
  final int? previewUploadedFileID;

  const MemoryLinkAlbumItem({
    super.key,
    required this.title,
    this.fileCount,
    this.previewUploadedFileID,
  });

  Future<EnteFile?> _loadPreviewFile() async {
    final uploadedID = previewUploadedFileID;
    if (uploadedID != null) {
      return FilesDB.instance.getAnyUploadedFile(uploadedID);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.fill,
        border: Border.all(color: colorScheme.fill),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 6,
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: FutureBuilder<EnteFile?>(
                    future: _loadPreviewFile(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final String heroTag =
                            heroTagPrefix + snapshot.data!.tag;
                        return Hero(
                          tag: heroTag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ThumbnailWidget(
                              snapshot.data!,
                              key: ValueKey(heroTag),
                            ),
                          ),
                        );
                      }
                      return const NoThumbnailWidget();
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
                        Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              (fileCount ?? 0).toString() + "  \u2022  ",
                              style: textTheme.smallMuted,
                            ),
                            Icon(
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
            child: IconButtonWidget(
              icon: Icons.chevron_right_outlined,
              iconButtonType: IconButtonType.secondary,
              iconColor: colorScheme.blurStrokePressed,
            ),
          ),
        ],
      ),
    );
  }
}
