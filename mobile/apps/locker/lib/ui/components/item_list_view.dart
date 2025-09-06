import 'dart:io';

import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/components/buttons/models/button_type.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_utils/share_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/services/files/download/file_downloader.dart';
import 'package:locker/services/files/links/links_service.dart';
import 'package:locker/services/files/sync/metadata_updater_service.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/ui/components/file_edit_dialog.dart';
import 'package:locker/ui/pages/collection_page.dart';
import 'package:locker/utils/collection_actions.dart';
import 'package:locker/utils/collection_sort_util.dart';
import 'package:locker/utils/date_time_util.dart';
import 'package:locker/utils/file_icon_utils.dart';
import 'package:locker/utils/snack_bar_utils.dart';
import 'package:open_file/open_file.dart';

class OverflowMenuAction {
  final String id;
  final String label;
  final IconData icon;
  final void Function(
    BuildContext context,
    EnteFile? file,
    Collection? collection,
  ) onTap;

  const OverflowMenuAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class ItemListView extends StatefulWidget {
  final List<EnteFile> files;
  final List<Collection> collections;
  final bool enableSorting;
  final Widget? emptyStateWidget;
  final List<OverflowMenuAction>? fileOverflowActions;
  final List<OverflowMenuAction>? collectionOverflowActions;

  const ItemListView({
    super.key,
    this.files = const [],
    this.collections = const [],
    this.enableSorting = false,
    this.emptyStateWidget,
    this.fileOverflowActions,
    this.collectionOverflowActions,
  });

  @override
  State<ItemListView> createState() => _ItemListViewState();
}

class _ItemListViewState extends State<ItemListView> {
  List<_ListItem> _sortedItems = [];
  int _sortColumnIndex = 1;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _updateItems();
  }

  @override
  void didUpdateWidget(ItemListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.files != oldWidget.files ||
        widget.collections != oldWidget.collections) {
      _updateItems();
    }
  }

  void _updateItems() {
    final sortedCollections =
        CollectionSortUtil.getSortedCollections(widget.collections);

    _sortedItems = [
      ...sortedCollections.map((c) => _CollectionListItem(c)),
      ...widget.files.map((f) => _FileListItem(f)),
    ];

    if (widget.enableSorting) {
      _sortItems(_sortColumnIndex, _sortAscending);
    }
  }

  void _sortItems(int columnIndex, bool ascending) {
    if (!widget.enableSorting) return;

    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      final files = _sortedItems.whereType<_FileListItem>().toList();
      final collections =
          _sortedItems.whereType<_CollectionListItem>().toList();

      switch (columnIndex) {
        case 0:
          files.sort((a, b) {
            final nameA = a.name.toLowerCase();
            final nameB = b.name.toLowerCase();
            return ascending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
          });
          collections.sort((a, b) {
            return CollectionSortUtil.compareCollectionsWithFavoritesPriority(
              a.collection,
              b.collection,
              ascending,
            );
          });
          break;
        case 1:
          files.sort((a, b) {
            final dateA = a.modificationTime;
            final dateB = b.modificationTime;
            return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
          });
          collections.sort((a, b) {
            return CollectionSortUtil
                .compareCollectionsByDateWithFavoritesPriority(
              a.collection,
              b.collection,
              ascending,
            );
          });
          break;
      }

      _sortedItems = [...collections, ...files];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sortedItems.isEmpty && widget.emptyStateWidget != null) {
      return widget.emptyStateWidget!;
    }

    if (_sortedItems.isEmpty) {
      return _buildDefaultEmptyState(context);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.enableSorting) _buildSortingHeader(context),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _sortedItems.length,
            itemBuilder: (context, index) {
              final item = _sortedItems[index];
              final isLastItem = index == _sortedItems.length - 1;
              return ListItemWidget(
                item: item,
                collections: widget.collections,
                fileOverflowActions: widget.fileOverflowActions,
                collectionOverflowActions: widget.collectionOverflowActions,
                isLastItem: isLastItem,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noFilesFound,
              style: getEnteTextTheme(context).body.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortingHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () =>
                  _sortItems(0, _sortColumnIndex == 0 ? !_sortAscending : true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_sortColumnIndex == 0)
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () =>
                  _sortItems(1, _sortColumnIndex == 1 ? !_sortAscending : true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.date,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_sortColumnIndex == 1)
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

abstract class _ListItem {
  String get name;
  DateTime get modificationTime;
  bool get isCollection;

  Collection? get collection => null;

  EnteFile? get file => null;
}

class _CollectionListItem extends _ListItem {
  final Collection _collection;

  _CollectionListItem(this._collection);

  @override
  String get name {
    return _collection.name ?? 'Unnamed Collection';
  }

  @override
  DateTime get modificationTime {
    return DateTime.fromMicrosecondsSinceEpoch(_collection.updationTime);
  }

  @override
  bool get isCollection => true;

  @override
  Collection get collection => _collection;
}

class _FileListItem extends _ListItem {
  final EnteFile _file;

  _FileListItem(this._file);

  @override
  String get name {
    return _file.displayName;
  }

  @override
  DateTime get modificationTime {
    if (_file.updationTime != null) {
      return DateTime.fromMicrosecondsSinceEpoch(_file.updationTime!);
    }
    if (_file.modificationTime != null) {
      return DateTime.fromMillisecondsSinceEpoch(_file.modificationTime!);
    }
    if (_file.creationTime != null) {
      return DateTime.fromMillisecondsSinceEpoch(_file.creationTime!);
    }
    return DateTime.now();
  }

  @override
  bool get isCollection => false;

  @override
  EnteFile get file => _file;
}

class ListItemWidget extends StatelessWidget {
  // ignore: library_private_types_in_public_api
  final _ListItem item;
  final List<Collection> collections;
  final List<OverflowMenuAction>? fileOverflowActions;
  final List<OverflowMenuAction>? collectionOverflowActions;
  final bool isLastItem;

  const ListItemWidget({
    super.key,
    // ignore: library_private_types_in_public_api
    required this.item,
    required this.collections,
    this.fileOverflowActions,
    this.collectionOverflowActions,
    this.isLastItem = false,
  });

  @override
  Widget build(BuildContext context) {
    if (item.isCollection && item.collection != null) {
      return CollectionRowWidget(
        collection: item.collection!,
        overflowActions: collectionOverflowActions,
        isLastItem: isLastItem,
      );
    } else if (!item.isCollection && item.file != null) {
      return FileRowWidget(
        file: item.file!,
        collections: collections,
        overflowActions: fileOverflowActions,
        isLastItem: isLastItem,
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(context.l10n.unknownItemType),
      );
    }
  }
}

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
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
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
                  ];
                }
              },
            ),
          ],
        ),
      ),
    );
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
}

class FileRowWidget extends StatelessWidget {
  final EnteFile file;
  final List<Collection> collections;
  final List<OverflowMenuAction>? overflowActions;
  final bool isLastItem;

  const FileRowWidget({
    super.key,
    required this.file,
    required this.collections,
    this.overflowActions,
    this.isLastItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final updateTime = file.updationTime != null
        ? DateTime.fromMicrosecondsSinceEpoch(file.updationTime!)
        : (file.modificationTime != null
            ? DateTime.fromMillisecondsSinceEpoch(file.modificationTime!)
            : (file.creationTime != null
                ? DateTime.fromMillisecondsSinceEpoch(file.creationTime!)
                : DateTime.now()));

    return InkWell(
      onTap: () => _openFile(context),
      child: Container(
        padding: EdgeInsets.fromLTRB(16.0, 2, 16.0, isLastItem ? 8 : 2),
        decoration: BoxDecoration(
          border: isLastItem
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FileIconUtils.getFileIcon(file.displayName),
                          color:
                              FileIconUtils.getFileIconColor(file.displayName),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            file.displayName,
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
                    PopupMenuItem<String>(
                      value: 'share_link',
                      child: Row(
                        children: [
                          const Icon(Icons.share, size: 16),
                          const SizedBox(width: 8),
                          Text(context.l10n.share),
                        ],
                      ),
                    ),
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
                  ];
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    if (overflowActions != null && overflowActions!.isNotEmpty) {
      final customAction = overflowActions!.firstWhere(
        (a) => a.id == action,
        orElse: () => throw StateError('Action not found'),
      );
      customAction.onTap(context, file, null);
    } else {
      switch (action) {
        case 'edit':
          _showEditDialog(context);
          break;
        case 'share_link':
          _shareLink(context);
          break;
        case 'delete':
          _showDeleteConfirmationDialog(context);
          break;
      }
    }
  }

  Future<void> _shareLink(BuildContext context) async {
    final dialog = createProgressDialog(
      context,
      context.l10n.creatingShareLink,
      isDismissible: false,
    );

    try {
      await dialog.show();

      // Get or create the share link
      final shareableLink = await LinksService.instance.getOrCreateLink(file);

      await dialog.hide();

      // Show the link dialog with copy and delete options
      if (context.mounted) {
        await _showShareLinkDialog(
          context,
          shareableLink.fullURL!,
          shareableLink.linkID,
        );
      }
    } catch (e) {
      await dialog.hide();

      if (context.mounted) {
        SnackBarUtils.showWarningSnackBar(
          context,
          '${context.l10n.failedToCreateShareLink}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _showShareLinkDialog(
    BuildContext context,
    String url,
    String linkID,
  ) async {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    // Capture the root context (with Scaffold) before showing dialog
    final rootContext = context;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                dialogContext.l10n.share,
                style: textTheme.largeBold,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dialogContext.l10n.shareThisLink,
                    style: textTheme.body,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.fillFaint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.strokeFaint),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            url,
                            style: textTheme.small,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CopyButton(
                          url: url,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _deleteShareLink(rootContext, file.uploadedFileID!);
                  },
                  child: Text(
                    dialogContext.l10n.deleteLink,
                    style:
                        textTheme.body.copyWith(color: colorScheme.warning500),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    // Use system share sheet to share the URL
                    await shareText(
                      url,
                      context: rootContext,
                    );
                  },
                  child: Text(
                    dialogContext.l10n.shareLink,
                    style:
                        textTheme.body.copyWith(color: colorScheme.primary500),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteShareLink(BuildContext context, int fileID) async {
    final result = await showChoiceDialog(
      context,
      title: context.l10n.deleteShareLinkDialogTitle,
      body: context.l10n.deleteShareLinkConfirmation,
      firstButtonLabel: context.l10n.delete,
      secondButtonLabel: context.l10n.cancel,
      firstButtonType: ButtonType.critical,
      isCritical: true,
    );
    if (result?.action == ButtonAction.first && context.mounted) {
      final dialog = createProgressDialog(
        context,
        context.l10n.deletingShareLink,
        isDismissible: false,
      );

      try {
        await dialog.show();
        await LinksService.instance.deleteLink(fileID);
        await dialog.hide();

        if (context.mounted) {
          SnackBarUtils.showInfoSnackBar(
            context,
            context.l10n.shareLinkDeletedSuccessfully,
          );
        }
      } catch (e) {
        await dialog.hide();

        if (context.mounted) {
          SnackBarUtils.showWarningSnackBar(
            context,
            '${context.l10n.failedToDeleteShareLink}: ${e.toString()}',
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final result = await showChoiceDialog(
      context,
      title: context.l10n.deleteFile,
      body: context.l10n.deleteFileConfirmation(file.displayName),
      firstButtonLabel: context.l10n.delete,
      secondButtonLabel: context.l10n.cancel,
      firstButtonType: ButtonType.critical,
      isCritical: true,
    );

    if (result?.action == ButtonAction.first && context.mounted) {
      await _deleteFile(context);
    }
  }

  Future<void> _deleteFile(BuildContext context) async {
    final dialog = createProgressDialog(
      context,
      context.l10n.deletingFile,
      isDismissible: false,
    );

    try {
      await dialog.show();

      final collections =
          await CollectionService.instance.getCollectionsForFile(file);
      if (collections.isNotEmpty) {
        await CollectionService.instance.trashFile(file, collections.first);
      }

      await dialog.hide();

      SnackBarUtils.showInfoSnackBar(
        context,
        context.l10n.fileDeletedSuccessfully,
      );
    } catch (e) {
      await dialog.hide();

      SnackBarUtils.showWarningSnackBar(
        context,
        context.l10n.failedToDeleteFile(e.toString()),
      );
    }
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final allCollections = await CollectionService.instance.getCollections();
    allCollections.removeWhere(
      (c) => c.type == CollectionType.uncategorized,
    );

    final result = await showFileEditDialog(
      context,
      file: file,
      collections: allCollections,
    );

    if (result != null && context.mounted) {
      List<Collection> currentCollections;
      try {
        currentCollections =
            await CollectionService.instance.getCollectionsForFile(file);
      } catch (e) {
        currentCollections = <Collection>[];
      }

      final currentCollectionsSet = currentCollections.toSet();

      final newCollectionsSet = result.selectedCollections.toSet();

      final collectionsToAdd =
          newCollectionsSet.difference(currentCollectionsSet).toList();

      final collectionsToRemove =
          currentCollectionsSet.difference(newCollectionsSet).toList();

      final currentTitle = file.displayName;
      final currentCaption = file.caption ?? '';
      final hasMetadataChanged =
          result.title != currentTitle || result.caption != currentCaption;

      if (hasMetadataChanged || currentCollectionsSet != newCollectionsSet) {
        final dialog = createProgressDialog(
          context,
          context.l10n.pleaseWait,
          isDismissible: false,
        );
        await dialog.show();

        try {
          final List<Future<void>> apiCalls = [];
          for (final collection in collectionsToAdd) {
            apiCalls.add(
              CollectionService.instance.addToCollection(collection, file),
            );
          }
          await Future.wait(apiCalls);
          apiCalls.clear();

          for (final collection in collectionsToRemove) {
            apiCalls.add(
              CollectionService.instance
                  .move(file, collection, newCollectionsSet.first),
            );
          }
          if (hasMetadataChanged) {
            apiCalls.add(
              MetadataUpdaterService.instance
                  .editFileNameAndCaption(file, result.title, result.caption),
            );
          }
          await Future.wait(apiCalls);

          await dialog.hide();

          SnackBarUtils.showInfoSnackBar(
            context,
            context.l10n.fileUpdatedSuccessfully,
          );
        } catch (e) {
          await dialog.hide();

          SnackBarUtils.showWarningSnackBar(
            context,
            context.l10n.failedToUpdateFile(e.toString()),
          );
        }
      } else {
        SnackBarUtils.showWarningSnackBar(
          context,
          context.l10n.noChangesWereMade,
        );
      }
    }
  }

  Future<void> _openFile(BuildContext context) async {
    if (file.localPath != null) {
      final localFile = File(file.localPath!);
      if (await localFile.exists()) {
        await _launchFile(context, localFile, file.displayName);
        return;
      }
    }

    final String cachedFilePath =
        "${Configuration.instance.getCacheDirectory()}${file.displayName}";
    final File cachedFile = File(cachedFilePath);
    if (await cachedFile.exists()) {
      await _launchFile(context, cachedFile, file.displayName);
      return;
    }

    final dialog = createProgressDialog(
      context,
      context.l10n.downloading,
      isDismissible: false,
    );

    try {
      await dialog.show();
      final fileKey = await CollectionService.instance.getFileKey(file);
      final decryptedFile = await downloadAndDecrypt(
        file,
        fileKey,
        progressCallback: (downloaded, total) {
          if (total > 0 && downloaded >= 0) {
            final percentage =
                ((downloaded / total) * 100).clamp(0, 100).round();
            dialog.update(
              message: context.l10n.downloadingProgress(percentage),
            );
          } else {
            dialog.update(message: context.l10n.downloading);
          }
        },
        shouldUseCache: true,
      );

      await dialog.hide();

      if (decryptedFile != null) {
        await _launchFile(context, decryptedFile, file.displayName);
      } else {
        await showErrorDialog(
          context,
          context.l10n.downloadFailed,
          context.l10n.failedToDownloadOrDecrypt,
        );
      }
    } catch (e) {
      await dialog.hide();
      await showErrorDialog(
        context,
        context.l10n.errorOpeningFile,
        context.l10n.errorOpeningFileMessage(e.toString()),
      );
    }
  }

  Future<void> _launchFile(
    BuildContext context,
    File file,
    String fileName,
  ) async {
    try {
      await OpenFile.open(file.path);
    } catch (e) {
      await showErrorDialog(
        context,
        context.l10n.errorOpeningFile,
        context.l10n.couldNotOpenFile(e.toString()),
      );
    }
  }
}

class _CopyButton extends StatefulWidget {
  final String url;

  const _CopyButton({
    required this.url,
  });

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return IconButton(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: widget.url));
        setState(() {
          _isCopied = true;
        });
        // Reset the state after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isCopied = false;
            });
          }
        });
      },
      icon: Icon(
        _isCopied ? Icons.check : Icons.copy,
        size: 16,
        color: _isCopied ? colorScheme.primary500 : colorScheme.primary500,
      ),
      iconSize: 16,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(4),
      tooltip: _isCopied
          ? context.l10n.linkCopiedToClipboard
          : context.l10n.copyLink,
    );
  }
}

class FileListViewHelpers {
  static Widget createSearchEmptyState({
    required String searchQuery,
    String? message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? 'No results found for "$searchQuery"',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search query',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Widget createSearchEverywhereFooter({
    required String searchQuery,
    required VoidCallback onTap,
    BuildContext? context,
  }) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: context != null
                      ? Theme.of(context).primaryColor
                      : Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search everywhere for "$searchQuery"',
                        style: context != null
                            ? getEnteTextTheme(context).large.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).primaryColor,
                                )
                            : const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search across all collections and files',
                        style: context != null
                            ? getEnteTextTheme(context).body.copyWith(
                                  color: Colors.grey[600],
                                )
                            : TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FileDataTable extends StatelessWidget {
  final List<EnteFile> files;
  final Function(EnteFile)? onFileTap;
  final bool enableSorting;

  const FileDataTable({
    super.key,
    required this.files,
    this.onFileTap,
    this.enableSorting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text(
        'FileDataTable is deprecated. Use FileListView instead.',
        style: TextStyle(color: Colors.red),
      ),
    );
  }
}
