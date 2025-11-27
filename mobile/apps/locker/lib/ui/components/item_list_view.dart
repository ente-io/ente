import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_utils/ente_utils.dart";
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:locker/extensions/collection_extension.dart";
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/file_type.dart';
import 'package:locker/models/selected_collections.dart';
import 'package:locker/models/selected_files.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/info_file_service.dart';
import "package:locker/ui/components/collection_list_widget.dart";
import "package:locker/ui/components/empty_state_widget.dart";
import "package:locker/ui/components/file_list_widget.dart";
import 'package:locker/ui/pages/collection_page.dart';
import 'package:locker/utils/collection_sort_util.dart';

class OverflowMenuAction {
  final String id;
  final String label;
  final Widget icon;
  final bool isWarning;
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
    this.isWarning = false,
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
  final ScrollPhysics? physics;

  const ItemListView({
    super.key,
    this.files = const [],
    this.collections = const [],
    this.emptyStateWidget,
    this.fileOverflowActions,
    this.collectionOverflowActions,
    this.selectedCollections,
    this.selectedFiles,
    this.physics = const NeverScrollableScrollPhysics(),
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
    // TODO(aman): Re-enable collection multi-select when bulk actions return.
    return;
    // HapticFeedback.lightImpact();
    // widget.selectedCollections!.toggleSelection(collection);
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

    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      shrinkWrap: true,
      physics: widget.physics,
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
    return CollectionListWidget(
      collection: collection,
      overflowActions: widget.collectionOverflowActions,
      isLastItem: isLastItem,
      selectedCollections: widget.selectedCollections,
      onTapCallback: onTap,
      onLongPressCallback: onLongPress,
    );
  }

  Widget _createFileWidget({
    required EnteFile file,
    required bool isLastItem,
    Function(EnteFile)? onTap,
    Function(EnteFile)? onLongPress,
  }) {
    return FileListWidget(
      file: file,
      overflowActions: widget.fileOverflowActions,
      isLastItem: isLastItem,
      selectedFiles: widget.selectedFiles,
      onTapCallback: onTap,
      onLongPressCallback: onLongPress,
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
    return _collection.displayName ?? 'Unnamed Collection';
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
    required BuildContext context,
    required String searchQuery,
    String? message,
  }) {
    return Center(
      child: EmptyStateWidget(
        assetPath: 'assets/empty_state.png',
        title: context.l10n.searchEmptyTitle,
        subtitle: context.l10n.searchEmptyDescription,
        showBorder: false,
      ),
    );
  }

  static Widget createSearchEverywhereFooter({
    required BuildContext context,
    required String searchQuery,
    required VoidCallback onTap,
  }) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
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
                  color: colorScheme.primary700,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.searchEverywhereTitle(searchQuery),
                        style: textTheme.large.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.searchEverywhereSubtitle,
                        style: textTheme.body.copyWith(
                          color: colorScheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.textMuted,
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
