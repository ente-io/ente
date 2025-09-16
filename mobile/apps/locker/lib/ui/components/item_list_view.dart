import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import "package:locker/ui/components/collection_row_widget.dart";
import "package:locker/ui/components/file_row_widget.dart";
import 'package:locker/utils/collection_sort_util.dart';

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.enableSorting) _buildSortingHeader(context),
        ListView.separated(
          separatorBuilder: (context, index) {
            return const SizedBox(height: 8);
          },
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                        color: getEnteColorScheme(context).textMuted,
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
                        color: getEnteColorScheme(context).textMuted,
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
