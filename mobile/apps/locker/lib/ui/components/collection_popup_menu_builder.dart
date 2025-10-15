import "package:ente_events/event_bus.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/events/collections_updated_event.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/collections/models/collection_view_type.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/item_list_view.dart";
import "package:locker/ui/pages/collection_page.dart";
import "package:locker/utils/collection_actions.dart";

/// Centralized builder for collection popup menus and actions
///
/// This class provides:
/// - Menu item building for collection popup menus
/// - Centralized action handling for edit, delete, and leave collection
/// - Navigation helper for opening collection pages
class CollectionPopupMenuBuilder {
  /// Builds popup menu items based on collection view type and overflow actions
  static List<PopupMenuItem<String>> buildPopupMenuItems(
    BuildContext context,
    Collection collection,
    List<OverflowMenuAction>? overflowActions,
  ) {
    if (overflowActions != null && overflowActions.isNotEmpty) {
      return overflowActions
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

    final collectionViewType =
        getCollectionViewType(collection, Configuration.instance.getUserID()!);

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

  /// Handles popup menu actions for collections
  ///
  /// This method centralizes all collection action handling:
  /// - Custom overflow actions
  /// - Edit collection (rename)
  /// - Delete collection
  /// - Leave shared collection
  ///
  /// Optional callbacks can be provided to override default behavior
  static void handleMenuAction(
    BuildContext context,
    String action,
    Collection collection,
    List<OverflowMenuAction>? overflowActions, {
    VoidCallback? onEditCallback,
    VoidCallback? onDeleteCallback,
    VoidCallback? onLeaveCollectionCallback,
  }) {
    if (overflowActions != null && overflowActions.isNotEmpty) {
      final customAction = overflowActions.firstWhere(
        (a) => a.id == action,
        orElse: () => throw StateError('Action not found'),
      );
      customAction.onTap(context, null, collection);
      return;
    }

    switch (action) {
      case 'edit':
        if (onEditCallback != null) {
          onEditCallback();
        } else {
          editCollection(context, collection);
        }
        break;
      case 'delete':
        if (onDeleteCallback != null) {
          onDeleteCallback();
        } else {
          deleteCollection(context, collection);
        }
        break;
      case 'leave_collection':
        if (onLeaveCollectionCallback != null) {
          onLeaveCollectionCallback();
        } else {
          leaveCollection(context, collection);
        }
        break;
    }
  }

  /// Opens the collection page
  ///
  /// This is a centralized navigation helper that can be used by both
  /// CollectionRowWidget and CollectionListWidget
  static void openCollection(BuildContext context, Collection collection) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CollectionPage(collection: collection),
      ),
    );
  }

  /// Shows a dialog to edit/rename a collection
  ///
  /// This method wraps CollectionActions.editCollection and ensures
  /// the UI is updated after a successful rename
  static Future<void> editCollection(
    BuildContext context,
    Collection collection,
  ) async {
    await CollectionActions.editCollection(
      context,
      collection,
      onSuccess: () {
        Bus.instance.fire(CollectionsUpdatedEvent());
      },
    );
  }

  /// Shows a confirmation dialog and deletes a collection
  ///
  /// This method wraps CollectionActions.deleteCollection and ensures
  /// the UI is updated after a successful deletion
  static Future<void> deleteCollection(
    BuildContext context,
    Collection collection,
  ) async {
    await CollectionActions.deleteCollection(
      context,
      collection,
      onSuccess: () {
        Bus.instance.fire(CollectionsUpdatedEvent());
      },
    );
  }

  /// Shows a confirmation dialog and leaves a shared collection
  ///
  /// This method wraps CollectionActions.leaveCollection and ensures
  /// the UI is updated after successfully leaving
  static Future<void> leaveCollection(
    BuildContext context,
    Collection collection,
  ) async {
    await CollectionActions.leaveCollection(
      context,
      collection,
      onSuccess: () {
        Bus.instance.fire(CollectionsUpdatedEvent());
      },
    );
  }
}
