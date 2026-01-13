import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_ui/components/buttons/icon_button_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/extensions/collection_extension.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/models/selected_collections.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/pages/collection_page.dart";
import "package:locker/ui/sharing/album_share_info_widget.dart";

class CollectionListWidget extends StatelessWidget {
  final Collection collection;
  final bool isLastItem;
  final SelectedCollections? selectedCollections;
  final void Function(Collection)? onTapCallback;
  final void Function(Collection)? onLongPressCallback;

  const CollectionListWidget({
    super.key,
    required this.collection,
    this.isLastItem = false,
    this.selectedCollections,
    this.onTapCallback,
    this.onLongPressCallback,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    final bool isFavourite = collection.type == CollectionType.favorites;
    final bool hasSharees = collection.sharees.isNotEmpty;

    final int? currentUserID = Configuration.instance.getUserID();
    final bool isOwner =
        currentUserID != null && collection.isOwner(currentUserID);
    final bool isOutgoing = isOwner && hasSharees;
    final bool isIncoming = !isOwner;
    final bool showSharingIndicator = isOutgoing || isIncoming;

    final collectionRowWidget = Flexible(
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.backgroundElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: collection.type == CollectionType.favorites
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedStar,
                              color: colorScheme.primary700,
                            )
                          : HugeIcon(
                              icon: HugeIcons.strokeRoundedWallet05,
                              color: colorScheme.textBase,
                            ),
                    ),
                  ),
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
                  collection.displayName ?? 'Unnamed Collection',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                FutureBuilder<int>(
                  future: CollectionService.instance.getFileCount(collection),
                  builder: (context, snapshot) {
                    final fileCount = snapshot.data ?? 0;
                    return Text(
                      context.l10n.items(fileCount),
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
    );

    return GestureDetector(
      onTap: () {
        if (onTapCallback != null) {
          onTapCallback!(collection);
        } else {
          _openCollection(context);
        }
      },
      onLongPress: () {
        if (onLongPressCallback != null) {
          onLongPressCallback!(collection);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: ListenableBuilder(
        listenable: selectedCollections ?? ValueNotifier(false),
        builder: (context, _) {
          final bool isSelected =
              selectedCollections?.isCollectionSelected(collection) ?? false;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
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
                collectionRowWidget,
                if (!isFavourite)
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
                              ? _buildShareesAvatars(
                                  collection.sharees.whereType<User>().toList(),
                                )
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

  void _openCollection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CollectionPage(collection: collection),
      ),
    );
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
