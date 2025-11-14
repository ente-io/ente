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

class CollectionRowWidget extends StatelessWidget {
  final Collection collection;
  final List<OverflowMenuAction>? overflowActions;
  final bool isLastItem;
  final SelectedCollections? selectedCollections;
  final void Function(Collection)? onTapCallback;
  final void Function(Collection)? onLongPressCallback;

  const CollectionRowWidget({
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
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final collectionName =
        collection.displayName ?? context.l10n.unnamedCollection;
    final bool isFavourite = collection.type == CollectionType.favorites;

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
              borderRadius: BorderRadius.circular(20),
              color: colorScheme.backdropBase,
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.backgroundBase,
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collectionName,
                            style: textTheme.bodyBold,
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<int>(
                            future: CollectionService.instance
                                .getFileCount(collection),
                            builder: (context, snapshot) {
                              final fileCount = snapshot.data ?? 0;
                              return Text(
                                context.l10n.items(fileCount),
                                style: textTheme.small.copyWith(
                                  color: colorScheme.textMuted,
                                ),
                                textAlign: TextAlign.left,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    isFavourite
                        ? const SizedBox.shrink()
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: isSelected
                                ? const SizedBox.shrink()
                                : CollectionPopupMenuWidget(
                                    collection: collection,
                                    overflowActions: overflowActions,
                                  ),
                          ),
                  ],
                ),
                const SizedBox(height: 4),
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
