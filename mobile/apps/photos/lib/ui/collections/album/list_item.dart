import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class AlbumListItemWidget extends StatelessWidget {
  final Collection collection;
  final void Function(Collection)? onTapCallback;
  final void Function(Collection)? onLongPressCallback;
  final SelectedAlbums? selectedAlbums;

  const AlbumListItemWidget(
    this.collection, {
    super.key,
    this.onTapCallback,
    this.onLongPressCallback,
    this.selectedAlbums,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    const sideOfThumbnail = 60.0;

    final albumWidget = Flexible(
      flex: 6,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: sideOfThumbnail,
              width: sideOfThumbnail,
              child: FutureBuilder<EnteFile?>(
                future: CollectionsService.instance.getCover(collection),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final thumbnail = snapshot.data!;
                    return ThumbnailWidget(
                      thumbnail,
                      showFavForAlbumOnly: true,
                      shouldShowOwnerAvatar: false,
                    );
                  } else {
                    return const NoThumbnailWidget(
                      addBorder: false,
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  collection.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
                FutureBuilder<int>(
                  future: CollectionsService.instance.getFileCount(collection),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        AppLocalizations.of(context).memoryCount(
                          count: snapshot.data!,
                          formattedCount: NumberFormat().format(snapshot.data!),
                        ),
                        style: textTheme.small.copyWith(
                          color: colorScheme.textMuted,
                        ),
                      );
                    } else {
                      if (snapshot.hasError) {
                        Logger("AlbumListItemWidget").severe(
                          "Failed to fetch file count of collection",
                          snapshot.error,
                        );
                      }
                      return Text(
                        "",
                        style: textTheme.small.copyWith(
                          color: colorScheme.textMuted,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () => onTapCallback?.call(collection),
      onLongPress: () => onLongPressCallback?.call(collection),
      behavior: HitTestBehavior.opaque,
      child: ListenableBuilder(
        listenable: selectedAlbums!,
        builder: (context, _) {
          final isSelected =
              selectedAlbums?.isAlbumSelected(collection) ?? false;

          return AnimatedContainer(
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? colorScheme.strokeMuted
                    : colorScheme.strokeFainter,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                albumWidget,
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
                        : IconButtonWidget(
                            key: const ValueKey("unselected"),
                            icon: Icons.chevron_right_outlined,
                            iconButtonType: IconButtonType.secondary,
                            iconColor: colorScheme.blurStrokePressed,
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
}
