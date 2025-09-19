import 'dart:async';

import 'package:ente_events/event_bus.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/events/collections_updated_event.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/selected_collections.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/trash/trash_service.dart';
import 'package:locker/ui/components/item_list_view.dart';
import 'package:locker/ui/components/search_result_view.dart';
import 'package:locker/ui/mixins/search_mixin.dart';
import 'package:locker/ui/pages/collection_page.dart';
import 'package:locker/ui/pages/home_page.dart';
import 'package:locker/ui/pages/trash_page.dart';
import 'package:locker/utils/collection_sort_util.dart';
import 'package:logging/logging.dart';

enum UISectionType {
  incomingCollections,
  outgoingCollections,
  homeCollections,
}

class AllCollectionsPage extends StatefulWidget {
  final UISectionType viewType;
  final SelectedCollections? selectedCollections;

  const AllCollectionsPage({
    super.key,
    this.viewType = UISectionType.homeCollections,
    this.selectedCollections,
  });

  @override
  State<AllCollectionsPage> createState() => _AllCollectionsPageState();
}

class _AllCollectionsPageState extends State<AllCollectionsPage>
    with SearchMixin {
  List<Collection> _sortedCollections = [];
  List<Collection> _allCollections = [];
  Collection? _uncategorizedCollection;
  int? _uncategorizedFileCount;
  List<EnteFile> _allFiles = [];
  bool _isLoading = true;
  String? _error;
  bool showTrash = false;
  bool showUncategorized = false;
  final _logger = Logger("AllCollectionsPage");

  @override
  List<Collection> get allCollections => _allCollections;

  @override
  List<EnteFile> get allFiles => _allFiles;

  @override
  void onSearchResultsChanged(
    List<Collection> collections,
    List<EnteFile> files,
  ) {
    setState(() {
      if (searchQuery.isEmpty) {
        final regularCollections = collections
            .where((c) => c.type != CollectionType.uncategorized)
            .toList();
        _sortedCollections =
            CollectionSortUtil.getSortedCollections(regularCollections);
      } else {
        _sortedCollections =
            CollectionSortUtil.getSortedCollections(collections);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCollections();
    Bus.instance.on<CollectionsUpdatedEvent>().listen((event) async {
      await _loadCollections();
    });
    if (widget.viewType == UISectionType.homeCollections) {
      showTrash = true;
      showUncategorized = true;
    }
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Collection> collections = [];

      if (widget.viewType == UISectionType.homeCollections) {
        collections = await CollectionService.instance.getCollections();
      } else {
        final sharedCollections =
            await CollectionService.instance.getSharedCollections();
        if (widget.viewType == UISectionType.outgoingCollections) {
          collections = sharedCollections.outgoing;
        } else if (widget.viewType == UISectionType.incomingCollections) {
          collections = sharedCollections.incoming;
        }
      }

      final regularCollections = <Collection>[];
      Collection? uncategorized;

      for (final collection in collections) {
        if (collection.type == CollectionType.uncategorized) {
          uncategorized = collection;
        } else {
          regularCollections.add(collection);
        }
      }

      CollectionSortUtil.sortCollections(regularCollections);

      _allCollections = List.from(collections);
      _sortedCollections = List.from(regularCollections);
      _uncategorizedCollection =
          widget.viewType == UISectionType.homeCollections
              ? uncategorized
              : null;
      _uncategorizedFileCount = uncategorized != null &&
              widget.viewType == UISectionType.homeCollections
          ? (await CollectionService.instance
                  .getFilesInCollection(uncategorized))
              .length
          : 0;
      _allFiles = await CollectionService.instance.getAllFiles();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe("Failed to load collections", e);
      setState(() {
        _error = 'Failed to load collections: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          leading: buildSearchLeading(),
          title: Text(_getTitle(context)),
          centerTitle: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          actions: [
            buildSearchAction(),
            ...buildSearchActions(),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: widget.selectedCollections != null
            ? ListenableBuilder(
                listenable: widget.selectedCollections!,
                builder: (context, _) {
                  return widget.selectedCollections!.hasSelections
                      ? _buildSelectionActionBar()
                      : const SizedBox.shrink();
                },
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCollections,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    if (isSearchActive) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SearchResultView(
          collections: _sortedCollections,
          files: const [],
          searchQuery: searchQuery,
          enableSorting: true,
          isHomePage: false,
          onSearchEverywhere: _searchEverywhere,
        ),
      );
    }

    if (_sortedCollections.isEmpty) {
      if (searchQuery.isNotEmpty) {
        return FileListViewHelpers.createSearchEmptyState(
          searchQuery: searchQuery,
          message: context.l10n.noCollectionsFoundForQuery(searchQuery),
        );
      } else {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.noCollectionsFound,
                  style: getEnteTextTheme(context).large.copyWith(
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(bottom: 16.0),
              alignment: Alignment.centerLeft,
              child: Text(
                '${_sortedCollections.length} result${_sortedCollections.length == 1 ? '' : 's'} for "$searchQuery"',
                style: getEnteTextTheme(context).small.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
            ),
          Flexible(
            child: ItemListView(
              collections: _sortedCollections,
              enableSorting: true,
              selectedCollections: widget.selectedCollections,
            ),
          ),
          if (!isSearchActive &&
              _uncategorizedCollection != null &&
              showUncategorized)
            _buildUncategorizedHook(),
          if (showTrash) _buildTrashHook(),
        ],
      ),
    );
  }

  Widget _buildTrashHook() {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: InkWell(
        onTap: _openTrash,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(30),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(50),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(70),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.trash,
                  style: getEnteTextTheme(context).large.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha(60),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTrash() async {
    final trashFiles = await TrashService.instance.getTrashFiles();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrashPage(trashFiles: trashFiles),
      ),
    );
  }

  void _searchEverywhere() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomePage(initialSearchQuery: searchQuery),
      ),
      (route) => false,
    );
  }

  Widget _buildUncategorizedHook() {
    if (_uncategorizedCollection == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: InkWell(
        onTap: () => _openUncategorized(),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(30),
            border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(50),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_open_outlined,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color?.withAlpha(70),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      context.l10n.uncategorized,
                      style: getEnteTextTheme(context).large.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (_uncategorizedFileCount! > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: getEnteTextTheme(context).small.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withAlpha(50),
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_uncategorizedFileCount!}',
                        style: getEnteTextTheme(context).small.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withAlpha(70),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withAlpha(60),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUncategorized() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CollectionPage(collection: _uncategorizedCollection!),
      ),
    );
  }

  Widget _buildSelectionActionBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final colorScheme = getEnteColorScheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                ListenableBuilder(
                  listenable: widget.selectedCollections!,
                  builder: (context, child) {
                    final isAllSelected = widget.selectedCollections!.count ==
                        _sortedCollections.length;
                    final buttonText =
                        isAllSelected ? 'Deselect all' : 'Select all';
                    final iconData = isAllSelected
                        ? Icons.remove_circle_outline
                        : Icons.check_circle_outline_outlined;

                    return InkWell(
                      onTap: () {
                        if (isAllSelected) {
                          widget.selectedCollections!.clearAll();
                        } else {
                          widget.selectedCollections!
                              .select(_sortedCollections.toSet());
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.strokeMuted,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          color: colorScheme.backgroundElevated2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              buttonText,
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              iconData,
                              color: Colors.grey,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                ListenableBuilder(
                  listenable: widget.selectedCollections!,
                  builder: (context, child) {
                    final count = widget.selectedCollections!.count;
                    final countText =
                        count == 1 ? '1 selected' : '$count selected';

                    return InkWell(
                      onTap: () {
                        widget.selectedCollections!.clearAll();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.strokeMuted,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          color: colorScheme.backgroundElevated2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              countText,
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.close,
                              size: 15,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            elevation: 4,
            color: isDarkMode
                ? colorScheme.fillFaint
                : colorScheme.backgroundElevated2,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 28 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return ListenableBuilder(
      listenable: widget.selectedCollections!,
      builder: (context, child) {
        final selectedCollections = widget.selectedCollections!.collections;
        if (selectedCollections.isEmpty) {
          return const SizedBox.shrink();
        }

        final actions = _getActionsForSelection(selectedCollections);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? getEnteColorScheme(context).backgroundElevated2
                : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: actions,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _getActionsForSelection(
    Set<Collection> selectedCollections,
  ) {
    final isSingleSelection = selectedCollections.length == 1;
    final collection = isSingleSelection ? selectedCollections.first : null;
    final actions = <Widget>[];

    if (isSingleSelection) {
      actions.addAll([
        _buildActionButton(
          icon: Icons.share_outlined,
          label: context.l10n.share,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Share ${collection?.name ?? 'Collection'}'),
              ),
            );
          },
        ),
        _buildActionButton(
          icon: Icons.edit_outlined,
          label: context.l10n.edit,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rename ${collection?.name ?? 'Collection'}'),
              ),
            );
          },
        ),
        _buildActionButton(
          icon: Icons.delete_outline,
          label: context.l10n.delete,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Delete ${collection?.name ?? 'Collection'}'),
              ),
            );
          },
          isDestructive: true,
        ),
      ]);
    } else {
      actions.addAll([
        _buildActionButton(
          icon: Icons.share_outlined,
          label: 'Share All',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Share ${selectedCollections.length} collections'),
              ),
            );
          },
        ),
        _buildActionButton(
          icon: Icons.delete_outline,
          label: 'Delete All',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Delete ${selectedCollections.length} collections'),
              ),
            );
          },
          isDestructive: true,
        ),
      ]);
    }
    return actions;
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final color = isDestructive ? Colors.red : colorScheme.textBase;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      highlightColor: color.withValues(alpha: 0.1),
      splashColor: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: textTheme.small.copyWith(
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(BuildContext context) {
    switch (widget.viewType) {
      case UISectionType.homeCollections:
        return context.l10n.collections;
      case UISectionType.outgoingCollections:
        return context.l10n.sharedByYou;
      case UISectionType.incomingCollections:
        return context.l10n.sharedWithYou;
    }
  }
}
