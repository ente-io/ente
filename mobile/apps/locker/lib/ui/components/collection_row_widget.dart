import "package:ente_events/event_bus.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/events/collections_updated_event.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/collections/models/collection_view_type.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/item_list_view.dart";
import "package:locker/ui/pages/collection_page.dart";
import "package:locker/utils/collection_actions.dart";
import "package:locker/utils/date_time_util.dart";

class CollectionRowWidget extends StatelessWidget {
  final Collection collection;
  final List<OverflowMenuAction>? overflowActions;
  final bool isLastItem;

  const CollectionRowWidget({
    super.key,
    required this.collection,
    this.overflowActions,
    this.isLastItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final updateTime =
        DateTime.fromMicrosecondsSinceEpoch(collection.updationTime);

    return InkWell(
      onTap: () => _openCollection(context),
      child: Container(
        padding: EdgeInsets.fromLTRB(16.0, 2, 16.0, isLastItem ? 8 : 2),
        decoration: BoxDecoration(
          border: isLastItem
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withAlpha(30),
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.folder_open,
                        color: collection.type == CollectionType.favorites
                            ? getEnteColorScheme(context).primary500
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          collection.name ?? 'Unnamed Collection',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: getEnteTextTheme(context).body,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                formatDate(context, updateTime),
                style: getEnteTextTheme(context).small.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value),
              icon: const Icon(
                Icons.more_vert,
                size: 20,
              ),
              itemBuilder: (BuildContext context) {
                return _buildPopupMenuItems(context);
              },
            ),
          ],
        ),
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
