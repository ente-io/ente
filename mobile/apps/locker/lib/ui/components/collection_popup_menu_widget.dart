import "package:ente_events/event_bus.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/events/collections_updated_event.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/collections/models/collection_view_type.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/item_list_view.dart";
import "package:locker/utils/collection_actions.dart";

class CollectionPopupMenuWidget extends StatelessWidget {
  final Collection collection;
  final List<OverflowMenuAction>? overflowActions;
  final Widget? child;

  const CollectionPopupMenuWidget({
    super.key,
    required this.collection,
    this.overflowActions,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(context, value),
      child: child ??
          HugeIcon(
            icon: HugeIcons.strokeRoundedMoreVertical,
            color: getEnteColorScheme(context).iconColor,
          ),
      itemBuilder: (BuildContext context) {
        return _buildPopupMenuItems(context);
      },
    );
  }

  List<PopupMenuItem<String>> _buildPopupMenuItems(BuildContext context) {
    if (overflowActions != null && overflowActions!.isNotEmpty) {
      return overflowActions!
          .map(
            (action) => PopupMenuItem<String>(
              value: action.id,
              child: Row(
                children: [
                  Icon(
                    action.icon,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(action.label),
                ],
              ),
            ),
          )
          .toList();
    }

    final collectionViewType = getCollectionViewType(
      collection,
      Configuration.instance.getUserID()!,
    );

    return [
      if (collectionViewType == CollectionViewType.ownedCollection ||
          collectionViewType == CollectionViewType.hiddenOwnedCollection ||
          collectionViewType == CollectionViewType.quickLink)
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedEdit02,
                size: 16,
              ),
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
              const HugeIcon(
                icon: HugeIcons.strokeRoundedDelete01,
                size: 16,
              ),
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
              const HugeIcon(
                icon: HugeIcons.strokeRoundedLogout02,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(context.l10n.leaveCollection),
            ],
          ),
        ),
    ];
  }

  void _handleMenuAction(BuildContext context, String action) {
    if (overflowActions != null && overflowActions!.isNotEmpty) {
      final customAction = overflowActions!.firstWhere(
        (a) => a.id == action,
        orElse: () => throw StateError('Action not found'),
      );
      customAction.onTap(context, null, collection);
      return;
    }

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

  Future<void> _editCollection(BuildContext context) async {
    await CollectionActions.editCollection(
      context,
      collection,
      onSuccess: () {
        Bus.instance.fire(CollectionsUpdatedEvent());
      },
    );
  }

  Future<void> _deleteCollection(BuildContext context) async {
    await CollectionActions.deleteCollection(
      context,
      collection,
      onSuccess: () {
        Bus.instance.fire(CollectionsUpdatedEvent());
      },
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
