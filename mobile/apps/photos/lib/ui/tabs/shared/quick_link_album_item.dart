import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/collection_share_badge.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class QuickLinkAlbumItem extends StatelessWidget {
  static const _thumbSize = 52.0;
  static const _cornerRadius = 12.0;
  static const _rowHeight = 68.0;
  static const _cardRadius = 20.0;

  final Collection c;
  static const heroTagPrefix = "outgoing_collection";
  final List<Collection> selectedQuickLinks;

  const QuickLinkAlbumItem({
    super.key,
    required this.c,
    this.selectedQuickLinks = const [],
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedQuickLinks.contains(c);
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

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
        borderRadius: const BorderRadius.all(Radius.circular(_cardRadius)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 6,
            child: Row(
              children: [
                SizedBox(
                  width: _thumbSize,
                  height: _thumbSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FutureBuilder<EnteFile?>(
                        future: CollectionsService.instance.getCover(c),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final String heroTag =
                                heroTagPrefix + snapshot.data!.tag;
                            return Hero(
                              tag: heroTag,
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(_cornerRadius),
                                child: ThumbnailWidget(
                                  snapshot.data!,
                                  key: ValueKey(heroTag),
                                ),
                              ),
                            );
                          } else {
                            return const NoThumbnailWidget(
                              addBorder: false,
                              borderRadius: _cornerRadius,
                            );
                          }
                        },
                      ),
                      const Positioned(
                        right: -4,
                        bottom: -4,
                        child: CollectionLinkBadge(),
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
                        c.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<int>(
                        future: CollectionsService.instance.getFileCount(c),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              AppLocalizations.of(context).itemCount(
                                count: snapshot.data!,
                              ),
                              style: textTheme.smallMuted,
                            );
                          }
                          return Text(
                            "",
                            style: textTheme.small.copyWith(
                              color: colorScheme.textMuted,
                            ),
                          );
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
                  ? const Padding(
                      key: ValueKey("selected"),
                      padding: EdgeInsets.only(right: 8),
                      child: CollectionSelectedBadge(),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
