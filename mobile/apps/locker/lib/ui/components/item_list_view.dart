import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_utils/ente_utils.dart";
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/file_type.dart';
import 'package:locker/models/item_view_type.dart';
import 'package:locker/models/selected_collections.dart';
import 'package:locker/models/selected_files.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/info_file_service.dart';
import "package:locker/ui/components/collection_list_widget.dart";
import "package:locker/ui/components/collection_row_widget.dart";
import "package:locker/ui/components/file_list_widget.dart";
import "package:locker/ui/components/file_row_widget.dart";
import 'package:locker/ui/pages/collection_page.dart';
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
  final Widget? emptyStateWidget;
  final List<OverflowMenuAction>? fileOverflowActions;
  final List<OverflowMenuAction>? collectionOverflowActions;
  final SelectedCollections? selectedCollections;
  final SelectedFiles? selectedFiles;
  final ItemViewType viewType;

  const ItemListView({
    super.key,
    this.files = const [],
    this.collections = const [],
    this.emptyStateWidget,
    this.fileOverflowActions,
    this.collectionOverflowActions,
    this.selectedCollections,
    this.selectedFiles,
    this.viewType = ItemViewType.listView,
  });

  @override
  State<ItemListView> createState() => _ItemListViewState();
}

class _ItemListViewState extends State<ItemListView> {
  List<_ListItem> _sortedItems = [];

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
  }

  Future<void> _navigateToCollectionPage(Collection collection) async {
    await routeToPage(context, CollectionPage(collection: collection));
  }

  void _toggleCollectionSelection(Collection collection) {
    HapticFeedback.lightImpact();
    widget.selectedCollections!.toggleSelection(collection);
  }

  void _toggleFileSelection(EnteFile file) {
    HapticFeedback.lightImpact();
    widget.selectedFiles!.toggleSelection(file);
  }

  @override
  Widget build(BuildContext context) {
    if (_sortedItems.isEmpty && widget.emptyStateWidget != null) {
      return widget.emptyStateWidget!;
    }

    if (_sortedItems.isEmpty) {
      return _buildDefaultEmptyState(context);
    }

    return widget.viewType == ItemViewType.gridView
        ? _buildGridView()
        : _buildListView();
  }

  Widget _buildListView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sortedItems.length,
          itemBuilder: (context, index) => _buildItem(index),
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: _sortedItems.length,
      itemBuilder: (context, index) => _buildItem(index),
    );
  }

  Widget _buildItem(int index) {
    final item = _sortedItems[index];
    final isLastItem = index == _sortedItems.length - 1;

    if (item.isCollection) {
      return _buildCollectionItem(item.collection!, isLastItem);
    } else {
      return _buildFileItem(item.file!, isLastItem);
    }
  }

  Widget _buildCollectionItem(Collection collection, bool isLastItem) {
    final hasSelection = widget.selectedCollections != null;

    if (hasSelection) {
      return ListenableBuilder(
        listenable: widget.selectedCollections!,
        builder: (context, child) {
          final isAnySelected = widget.selectedCollections!.hasSelections;
          return _createCollectionWidget(
            collection: collection,
            isLastItem: isLastItem,
            onTap: (c) => isAnySelected
                ? _toggleCollectionSelection(c)
                : _navigateToCollectionPage(c),
            onLongPress: (c) => isAnySelected
                ? _navigateToCollectionPage(c)
                : _toggleCollectionSelection(c),
          );
        },
      );
    }

    return _createCollectionWidget(
      collection: collection,
      isLastItem: isLastItem,
    );
  }

  Widget _buildFileItem(EnteFile file, bool isLastItem) {
    final hasSelection = widget.selectedFiles != null;

    if (hasSelection) {
      return ListenableBuilder(
        listenable: widget.selectedFiles!,
        builder: (context, child) {
          final isAnySelected = widget.selectedFiles!.hasSelections;
          return _createFileWidget(
            file: file,
            isLastItem: isLastItem,
            onTap: isAnySelected ? (f) => _toggleFileSelection(f) : null,
            onLongPress: isAnySelected ? null : (f) => _toggleFileSelection(f),
          );
        },
      );
    }

    return _createFileWidget(
      file: file,
      isLastItem: isLastItem,
    );
  }

  Widget _createCollectionWidget({
    required Collection collection,
    required bool isLastItem,
    Function(Collection)? onTap,
    Function(Collection)? onLongPress,
  }) {
    if (widget.viewType == ItemViewType.gridView) {
      return CollectionRowWidget(
        collection: collection,
        overflowActions: widget.collectionOverflowActions,
        isLastItem: isLastItem,
        selectedCollections: widget.selectedCollections,
        onTapCallback: onTap,
        onLongPressCallback: onLongPress,
      );
    } else {
      return CollectionListWidget(
        collection: collection,
        overflowActions: widget.collectionOverflowActions,
        isLastItem: isLastItem,
        selectedCollections: widget.selectedCollections,
        onTapCallback: onTap,
        onLongPressCallback: onLongPress,
      );
    }
  }

  Widget _createFileWidget({
    required EnteFile file,
    required bool isLastItem,
    Function(EnteFile)? onTap,
    Function(EnteFile)? onLongPress,
  }) {
    if (widget.viewType == ItemViewType.gridView) {
      return FileRowWidget(
        file: file,
        overflowActions: widget.fileOverflowActions,
        isLastItem: isLastItem,
        selectedFiles: widget.selectedFiles,
        onTapCallback: onTap,
        onLongPressCallback: onLongPress,
      );
    } else {
      return FileListWidget(
        file: file,
        collections: widget.collections,
        overflowActions: widget.fileOverflowActions,
        isLastItem: isLastItem,
        selectedFiles: widget.selectedFiles,
        onTapCallback: onTap,
        onLongPressCallback: onLongPress,
      );
    }
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
    // For info files, try to extract the title from the info data
    if (_file.fileType == FileType.info) {
      return InfoFileService.instance.getFileTitleFromFile(_file) ??
          _file.displayName;
    }
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
