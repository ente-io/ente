import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/services/collections_service.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/components/collection_share_badge.dart";
import "package:photos/ui/sharing/user_avator_widget.dart";
import 'package:photos/ui/viewer/file/no_thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';

///https://www.figma.com/design/SYtMyLBs5SAOkTbfMMzhqt/Ente-Visual-Design?node-id=39181-172145&t=3qmSZWpXF3ZC4JGN-1
class AlbumColumnItemWidget extends StatelessWidget {
  static const _thumbSize = 52.0;
  static const _cornerRadius = 12.0;
  static const _rowHeight = 68.0;
  static const _cardRadius = 20.0;

  final Collection collection;
  final List<Collection> selectedCollections;

  const AlbumColumnItemWidget(
    this.collection, {
    super.key,
    this.selectedCollections = const [],
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    final isSelected = selectedCollections.contains(collection);
    final isOwner = collection.isOwner(Configuration.instance.getUserID()!);
    return AnimatedContainer(
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 200),
      height: _rowHeight,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.fill,
        border: Border.all(
          color: isSelected ? colorScheme.greenStroke : colorScheme.fill,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(_cardRadius),
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
                  height: _thumbSize,
                  width: _thumbSize,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(_cornerRadius),
                        child: SizedBox(
                          height: _thumbSize,
                          width: _thumbSize,
                          child: FutureBuilder<EnteFile?>(
                            future: CollectionsService.instance
                                .getCover(collection),
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
                      if (!isOwner)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: UserAvatarWidget(
                            collection.owner,
                            type: AvatarType.small,
                            thumbnailView: true,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<int>(
                        future: CollectionsService.instance
                            .getFileCount(collection),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              AppLocalizations.of(context).itemCount(
                                count: snapshot.data!,
                              ),
                              style: textTheme.smallMuted,
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
          ),
          Flexible(
            flex: 1,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isSelected
                  ? const CollectionSelectedBadge(
                      key: ValueKey("selected"),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
