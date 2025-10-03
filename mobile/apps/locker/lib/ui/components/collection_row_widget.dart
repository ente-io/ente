import "package:ente_events/event_bus.dart";
import "package:ente_ui/components/buttons/icon_button_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/events/collections_updated_event.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/models/selected_collections.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/collections/models/collection_view_type.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/item_list_view.dart";
import "package:locker/ui/pages/collection_page.dart";
import "package:locker/utils/collection_actions.dart";

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
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    final collectionRowWidget = Flexible(
      flex: 6,
      child: Row(
        children: [
          SizedBox(
            height: 60,
            width: 48,
            child: Icon(
              Icons.folder_open,
              color: collection.type == CollectionType.favorites
                  ? colorScheme.primary500
                  : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  collection.name ?? 'Unnamed Collection',
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
                    ? colorScheme.strokeMuted
                    : colorScheme.strokeFainter,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                collectionRowWidget,
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
                        : PopupMenuButton<String>(
                            onSelected: (value) =>
                                _handleMenuAction(context, value),
                            icon: const Icon(
                              Icons.more_vert,
                              size: 20,
                            ),
                            itemBuilder: (BuildContext context) {
                              return _buildPopupMenuItems(context);
                            },
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

  List<PopupMenuItem<String>> _buildPopupMenuItems(BuildContext context) {
    final collectionViewType =
        getCollectionViewType(collection, Configuration.instance.getUserID()!);
    if (overflowActions != null && overflowActions!.isNotEmpty) {
      return overflowActions!
          .map(
            (action) => PopupMenuItem<String>(
              value: action.id,
              child: Row(
                children: [
                  Icon(action.icon, size: 16),
                  const SizedBox(width: 8),
                  Text(action.label),
                ],
              ),
            ),
          )
          .toList();
    } else {
      return [
        if (collectionViewType == CollectionViewType.ownedCollection ||
            collectionViewType == CollectionViewType.hiddenOwnedCollection ||
            collectionViewType == CollectionViewType.quickLink)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit, size: 16),
                const SizedBox(width: 8),
                Text(context.l10n.edit),
              ],
            ),
          ),
        if (collectionViewType == CollectionViewType.ownedCollection ||
            collectionViewType == CollectionViewType.hiddenOwnedCollection ||
            collectionViewType == CollectionViewType.quickLink)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, size: 16),
                const SizedBox(width: 8),
                Text(context.l10n.delete),
              ],
            ),
          ),
        if (collectionViewType == CollectionViewType.sharedCollection)
          PopupMenuItem<String>(
            value: 'leave_collection',
            child: Row(
              children: [
                const Icon(Icons.logout),
                const SizedBox(width: 12),
                Text(context.l10n.leaveCollection),
              ],
            ),
          ),
      ];
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    if (overflowActions != null && overflowActions!.isNotEmpty) {
      final customAction = overflowActions!.firstWhere(
        (a) => a.id == action,
        orElse: () => throw StateError('Action not found'),
      );
      customAction.onTap(context, null, collection);
    } else {
      switch (action) {
        case 'edit':
          _editCollection(context);
          break;
        case 'delete':
          _deleteCollection(context);
          break;
        case 'leave_collection':
          _leaveCollection(context);
          break;
      }
    }
  }

  void _editCollection(BuildContext context) {
    CollectionActions.editCollection(context, collection);
  }

  void _deleteCollection(BuildContext context) {
    CollectionActions.deleteCollection(context, collection);
  }

  void _openCollection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CollectionPage(collection: collection),
      ),
    );
  }

  Future<void> _leaveCollection(BuildContext context) async {
    await CollectionActions.leaveCollection(
      context,
      collection,
      onSuccess: () {
        Bus.instance.fire(CollectionsUpdatedEvent());
      },
    );
  }
}
