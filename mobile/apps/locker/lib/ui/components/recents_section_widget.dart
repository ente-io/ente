import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/ui/components/item_list_view.dart';

class RecentsSectionWidget extends StatefulWidget {
  final List<Collection> collections;
  final List<EnteFile> recentFiles;

  const RecentsSectionWidget({
    super.key,
    required this.collections,
    required this.recentFiles,
  });

  @override
  State<RecentsSectionWidget> createState() => _RecentsSectionWidgetState();
}

class _RecentsSectionWidgetState extends State<RecentsSectionWidget> {
  final Set<Collection> _selectedCollections = {};
  final List<Collection> _selectionOrder = [];
  List<EnteFile> _filteredFilesByCollections = [];
  List<Collection> _availableCollections = [];
  late List<Collection> _originalCollectionOrder;

  @override
  void initState() {
    super.initState();
    _originalCollectionOrder = List.from(widget.collections);
    _availableCollections = List.from(widget.collections);
    _updateFilteredFilesByCollections();
    _updateAvailableCollections();
  }

  @override
  void didUpdateWidget(RecentsSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recentFiles != widget.recentFiles ||
        oldWidget.collections != widget.collections) {
      _originalCollectionOrder = List.from(widget.collections);
      _updateFilteredFilesByCollections();
      _updateAvailableCollections();
    }
  }

  List<EnteFile> get _displayedFiles {
    if (_selectedCollections.isNotEmpty) {
      return _filteredFilesByCollections;
    } else {
      return widget.recentFiles;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecentsHeader(),
        const SizedBox(height: 12),
        if (widget.collections.isNotEmpty) ...[
          _buildCollectionChips(),
          const SizedBox(height: 16),
        ],
        _buildRecentsTable(),
      ],
    );
  }

  Widget _buildRecentsHeader() {
    return Text(
      'Recents',
      style: getEnteTextTheme(context).h3Bold,
    );
  }

  Widget _buildCollectionChips() {
    final orderedCollections = _getOrderedCollections();

    if (orderedCollections.isEmpty) {
      return SizedBox(
        height: 40,
        child: Center(
          child: Text(
            'No collections to filter by',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: ListView.builder(
                key: ValueKey(orderedCollections.map((c) => c.id).join('-')),
                scrollDirection: Axis.horizontal,
                itemCount: orderedCollections.length,
                itemBuilder: (context, index) {
                  final collection = orderedCollections[index];
                  final isSelected = _selectedCollections.contains(collection);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    child: _buildCollectionChip(collection, isSelected),
                  );
                },
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: _selectedCollections.isNotEmpty
                ? Container(
                    key: const ValueKey('clear_button'),
                    margin: const EdgeInsets.only(left: 8),
                    child: _buildClearAllButton(),
                  )
                : const SizedBox.shrink(key: ValueKey('no_clear_button')),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionChip(Collection collection, bool isSelected) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _onCollectionSelected(collection),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? getEnteColorScheme(context).fillMuted : null,
            border: Border.all(
              color: isSelected
                  ? getEnteColorScheme(context).strokeBase
                  : getEnteColorScheme(context).fillFaint,
              width: 1,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                collection.name ?? 'Untitled',
                style: getEnteTextTheme(context).mini,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: isSelected
                    ? Row(
                        key: const ValueKey('close_button'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _onCollectionSelected(collection),
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: getEnteColorScheme(context).strokeBase,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 10,
                                color: getEnteColorScheme(context).backdropBase,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('no_button')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearAllButton() {
    return GestureDetector(
      onTap: _clearAllSelections,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: getEnteColorScheme(context).fillFaint,
          border: Border.all(
            color: getEnteColorScheme(context).strokeMuted,
            width: 1,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(16.0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.clear_all,
              size: 14,
              color: getEnteColorScheme(context).textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              'Clear',
              style: getEnteTextTheme(context).miniMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentsTable() {
    if (_displayedFiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.folder_off,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No common items in selected collections',
                style: getEnteTextTheme(context).body.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ItemListView(
      files: _displayedFiles,
      enableSorting: true,
    );
  }

  void _onCollectionSelected(Collection collection) {
    HapticFeedback.lightImpact();

    setState(() {
      if (_selectedCollections.contains(collection)) {
        _selectedCollections.remove(collection);
        _selectionOrder.remove(collection);
      } else {
        _selectedCollections.add(collection);
        _selectionOrder.add(collection);
      }
    });

    _updateFilteredFilesByCollections();
    _updateAvailableCollections();
  }

  void _clearAllSelections() {
    HapticFeedback.lightImpact();

    setState(() {
      _selectedCollections.clear();
      _selectionOrder.clear();
    });

    _updateFilteredFilesByCollections();
    _updateAvailableCollections();
  }

  Future<void> _updateAvailableCollections() async {
    try {
      final collectionsWithCommonFiles = await _getCollectionsWithCommonFiles(
        _selectedCollections.toList(),
        widget.collections,
      );

      if (mounted) {
        setState(() {
          _availableCollections = collectionsWithCommonFiles;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableCollections = List.from(widget.collections);
        });
      }
    }
  }

  Future<void> _updateFilteredFilesByCollections() async {
    if (_selectedCollections.isEmpty) {
      _filteredFilesByCollections = [];
      return;
    }

    final filteredFiles = <EnteFile>[];
    for (final file in widget.recentFiles) {
      try {
        final fileCollections =
            await CollectionService.instance.getCollectionsForFile(file);
        final hasAllSelectedCollections = _selectedCollections.every(
          (selectedCollection) => fileCollections.contains(selectedCollection),
        );
        if (hasAllSelectedCollections) {
          filteredFiles.add(file);
        }
      } catch (e) {
        continue;
      }
    }

    if (mounted) {
      setState(() {
        _filteredFilesByCollections = filteredFiles;
      });
    }
  }

  Future<List<Collection>> _getCollectionsWithCommonFiles(
    List<Collection> selectedCollections,
    List<Collection> allCollections,
  ) async {
    if (selectedCollections.isEmpty) {
      return allCollections;
    }

    if (selectedCollections.length == allCollections.length) {
      return allCollections;
    }

    try {
      final Map<int, Set<int>> collectionFileCache = {};

      Future<Set<int>> getCollectionFileIds(Collection collection) async {
        if (collectionFileCache.containsKey(collection.id)) {
          return collectionFileCache[collection.id]!;
        }

        final files =
            await CollectionService.instance.getFilesInCollection(collection);
        final fileIds = files
            .where((file) => file.uploadedFileID != null)
            .map((file) => file.uploadedFileID!)
            .toSet();

        collectionFileCache[collection.id] = fileIds;
        return fileIds;
      }

      final selectedFileIdSets = await Future.wait(
        selectedCollections.map(getCollectionFileIds),
      );

      if (selectedFileIdSets.any((set) => set.isEmpty)) {
        return selectedCollections;
      }

      final commonFileIds =
          selectedFileIdSets.reduce((a, b) => a.intersection(b));

      if (commonFileIds.isEmpty) {
        return selectedCollections;
      }

      final result = <Collection>[];

      for (final collection in allCollections) {
        if (selectedCollections
            .any((selected) => selected.id == collection.id)) {
          result.add(collection);
        } else {
          final collectionFileIds = await getCollectionFileIds(collection);
          if (commonFileIds.any(collectionFileIds.contains)) {
            result.add(collection);
          }
        }
      }

      return result;
    } catch (e) {
      return allCollections;
    }
  }

  List<Collection> _getOrderedCollections() {
    final orderedCollections = <Collection>[];

    for (final collection in _selectionOrder) {
      if (_availableCollections.contains(collection)) {
        orderedCollections.add(collection);
      }
    }

    for (final collection in _originalCollectionOrder) {
      if (_availableCollections.contains(collection) &&
          !_selectedCollections.contains(collection)) {
        orderedCollections.add(collection);
      }
    }

    return orderedCollections;
  }
}
