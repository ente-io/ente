import "package:ente_ui/components/buttons/icon_button_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/extensions/collection_extension.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/models/selected_collections.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/ui/components/collection_popup_menu_widget.dart";
import "package:locker/ui/components/item_list_view.dart";
import "package:locker/ui/pages/collection_page.dart";

class CollectionListWidget extends StatelessWidget {
  final Collection collection;
  final List<OverflowMenuAction>? overflowActions;
  final bool isLastItem;
  final SelectedCollections? selectedCollections;
  final void Function(Collection)? onTapCallback;
  final void Function(Collection)? onLongPressCallback;

  const CollectionListWidget({
    super.key,
    required this.collection,
    this.overflowActions,
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

    final collectionRowWidget = Flexible(
      flex: 6,
      child: Row(
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: Padding(
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
                collectionRowWidget,
                isFavourite
                    ? const SizedBox.shrink()
                    : Flexible(
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
                                  iconColor: colorScheme.primary700,
                                )
                              : CollectionPopupMenuWidget(
                                  collection: collection,
                                  overflowActions: overflowActions,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedMoreVertical,
                                      color: colorScheme.textBase,
                                    ),
                                  ),
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
}
