import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class QuickLinkAlbumItem extends StatelessWidget {
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
                    future: CollectionsService.instance.getCover(c),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final String heroTag =
                            heroTagPrefix + snapshot.data!.tag;
                        return Hero(
                          tag: heroTag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: ThumbnailWidget(
                              snapshot.data!,
                              key: ValueKey(heroTag),
                            ),
                          ),
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
                        Text(
                          c.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        FutureBuilder<int>(
                          future: CollectionsService.instance.getFileCount(c),
                          builder: (context, snapshot) {
                            if (!snapshot.hasError) {
                              if (!snapshot.hasData) {
                                return Row(
                                  children: [
                                    EnteLoadingWidget(
                                      size: 10,
                                      color: colorScheme.strokeMuted,
                                    ),
                                  ],
                                );
                              }
                              final noOfMemories = snapshot.data;

                              return Row(
                                children: [
                                  Text(
                                    noOfMemories.toString() + "  \u2022  ",
                                    style: textTheme.smallMuted,
                                  ),
                                  c.hasLink
                                      ? (c.publicURLs.first.isExpired
                                          ? Icon(
                                              Icons.link_outlined,
                                              color: colorScheme.warning500,
                                              size: 22,
                                            )
                                          : Icon(
                                              Icons.link_outlined,
                                              color: colorScheme.strokeMuted,
                                              size: 22,
                                            ))
                                      : const SizedBox.shrink(),
                                ],
                              );
                            } else if (snapshot.hasError) {
                              return Text(
                                AppLocalizations.of(context).somethingWentWrong,
                              );
                            } else {
                              return const EnteLoadingWidget(size: 10);
                            }
                          },
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
  }
}
