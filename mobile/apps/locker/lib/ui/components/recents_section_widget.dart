import "package:ente_ui/theme/colors.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/text_style.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:hugeicons/hugeicons.dart";
import "package:locker/extensions/collection_extension.dart";
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/item_view_type.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import "package:locker/services/files/download/service_locator.dart";
import 'package:locker/services/files/sync/models/file.dart';
import "package:locker/ui/collections/section_title.dart";
import "package:locker/ui/components/empty_state_widget.dart";
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
  List<EnteFile> _filteredFiles = [];
  List<Collection> _availableCollections = [];
  late List<Collection> _originalCollectionOrder;
  int _filtersComputationId = 0;
  final Map<int, List<Collection>> _fileCollectionsCache = {};
  final Map<int, Future<List<Collection>>> _fileCollectionsRequests = {};
  ItemViewType? _viewType;

  @override
  void initState() {
    super.initState();
    _originalCollectionOrder = List.from(widget.collections);
    _availableCollections = List.from(widget.collections);
    _viewType = localSettings.itemViewType();
  }

  @override
  void didUpdateWidget(RecentsSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recentFiles != widget.recentFiles ||
        oldWidget.collections != widget.collections) {
      _handleCollectionUpdates();
      _fileCollectionsCache.clear();
      _fileCollectionsRequests.clear();
      setState(() {
        _originalCollectionOrder = List.from(widget.collections);
        if (!_hasActiveFilters) {
          _availableCollections = List.from(widget.collections);
        }
      });
      _updateFilteredFiles();
    }
  }

  bool get _hasActiveFilters => _selectedCollections.isNotEmpty;

  List<EnteFile> get _displayedFiles =>
      _hasActiveFilters ? _filteredFiles : widget.recentFiles;

  @override
  Widget build(BuildContext context) {
    final filterChipsRow = _buildFilterChipsRow();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecentsHeader(),
        const SizedBox(height: 12),
        if (filterChipsRow != null) ...[
          filterChipsRow,
          const SizedBox(height: 16),
        ],
        _buildRecentsTable(context),
      ],
    );
  }

  Widget _buildRecentsHeader() {
    final colorScheme = getEnteColorScheme(context);
    return SectionOptions(
      SectionTitle(title: context.l10n.recents),
      trailingWidget: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          localSettings.setItemViewType(
            _viewType == ItemViewType.listView
                ? ItemViewType.gridView
                : ItemViewType.listView,
          );
          setState(() {
            _viewType = _viewType == ItemViewType.listView
                ? ItemViewType.gridView
                : ItemViewType.listView;
          });
        },
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.backdropBase,
          ),
          padding: const EdgeInsets.all(12),
          child: HugeIcon(
            icon: _viewType == ItemViewType.listView
                ? HugeIcons.strokeRoundedGridView
                : HugeIcons.strokeRoundedMenu01,
            color: colorScheme.textBase,
          ),
        ),
      ),
    );
  }

  Widget? _buildFilterChipsRow() {
    final orderedFilters = _getOrderedCollections();

    if (orderedFilters.isEmpty) {
      return null;
    }

    final chipModels = orderedFilters
        .map(
          (collection) => _FilterChipViewModel(
            key: 'c_${collection.id}',
            label: _collectionLabel(collection),
            isSelected: _selectedCollections.contains(collection),
            onTap: () => _onCollectionSelected(collection),
          ),
        )
        .toList();

    return _FilterChipsRow(
      chips: chipModels,
      showClearButton: false,
      onClearTapped: _clearAllFilters,
    );
  }

  Widget _buildRecentsTable(BuildContext context) {
    if (_displayedFiles.isEmpty) {
      return EmptyStateWidget(
        assetPath: "assets/empty_state.png",
        subtitle: context.l10n.noItemsMatchSelectedFilters,
      );
    }

    return ItemListView(
      files: _displayedFiles,
      viewType: _viewType ?? ItemViewType.listView,
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

    _updateFilteredFiles();
  }

  void _clearAllFilters() {
    HapticFeedback.lightImpact();

    setState(() {
      _selectedCollections.clear();
      _selectionOrder.clear();
    });

    _updateFilteredFiles();
  }

  void _handleCollectionUpdates() {
    final updatedCollectionIds = widget.collections.map((c) => c.id).toSet();
    final removedCollections = _selectedCollections
        .where((collection) => !updatedCollectionIds.contains(collection.id))
        .toList();

    if (removedCollections.isEmpty) {
      return;
    }

    setState(() {
      for (final collection in removedCollections) {
        _selectedCollections.remove(collection);
        _selectionOrder.remove(collection);
      }
    });
  }

  Future<void> _updateFilteredFiles() async {
    final int computationId = ++_filtersComputationId;
    final hasCollectionFilters = _selectedCollections.isNotEmpty;
    final hasAnyFilters = hasCollectionFilters;

    if (!hasAnyFilters) {
      if (!mounted || computationId != _filtersComputationId) {
        return;
      }

      setState(() {
        _filteredFiles = [];
        _availableCollections = List.from(widget.collections);
      });
      return;
    }

    final fileCollections = await _ensureCollectionsForFiles(
      widget.recentFiles,
      refresh: hasCollectionFilters,
    );

    if (!mounted || computationId != _filtersComputationId) {
      return;
    }

    final filteredFiles = <EnteFile>[];
    final filteredFileCollections = <int, List<Collection>>{};
    final selectedCollectionIds =
        _selectedCollections.map((collection) => collection.id).toSet();

    for (final file in widget.recentFiles) {
      final fileId = file.uploadedFileID;
      final collectionsForFile = fileId != null
          ? (fileCollections[fileId] ?? const <Collection>[])
          : const <Collection>[];

      if (hasCollectionFilters) {
        final collectionIdsForFile =
            collectionsForFile.map((collection) => collection.id).toSet();

        if (!selectedCollectionIds.every(collectionIdsForFile.contains)) {
          continue;
        }
      }

      filteredFiles.add(file);
      if (fileId != null) {
        filteredFileCollections[fileId] = collectionsForFile;
      }
    }

    final availableCollections = _computeAvailableCollections(
      hasActiveFilters: hasAnyFilters,
      filteredFiles: filteredFiles,
      fileCollections: filteredFileCollections,
    );

    if (!mounted || computationId != _filtersComputationId) {
      return;
    }

    setState(() {
      _filteredFiles = filteredFiles;
      _availableCollections = availableCollections;
    });
  }

  Future<Map<int, List<Collection>>> _ensureCollectionsForFiles(
    List<EnteFile> files, {
    bool refresh = false,
  }) async {
    final List<Future<void>> pending = [];

    for (final file in files) {
      final fileId = file.uploadedFileID;
      if (fileId == null) {
        continue;
      }

      if (refresh) {
        _fileCollectionsCache.remove(fileId);
        // Drop any in-flight request so a fresh fetch is triggered.
        final _ = _fileCollectionsRequests.remove(fileId);
      }

      if (_fileCollectionsCache.containsKey(fileId)) {
        continue;
      }

      final existingRequest = _fileCollectionsRequests[fileId];
      if (existingRequest != null) {
        pending.add(
          existingRequest.then((collections) {
            _fileCollectionsCache[fileId] = collections;
          }).whenComplete(() {
            _fileCollectionsRequests.remove(fileId);
          }),
        );
        continue;
      }

      final request = CollectionService.instance.getCollectionsForFile(file);
      _fileCollectionsRequests[fileId] = request;
      pending.add(
        request.then((collections) {
          _fileCollectionsCache[fileId] = collections;
        }).whenComplete(() {
          _fileCollectionsRequests.remove(fileId);
        }),
      );
    }

    if (pending.isNotEmpty) {
      try {
        await Future.wait(pending);
      } catch (_) {
        // Ignore individual failures; missing entries default to empty lists.
      }
    }

    final result = <int, List<Collection>>{};
    for (final file in files) {
      final fileId = file.uploadedFileID;
      if (fileId == null) {
        continue;
      }
      result[fileId] = _fileCollectionsCache[fileId] ?? const [];
    }

    return result;
  }

  List<Collection> _computeAvailableCollections({
    required bool hasActiveFilters,
    required List<EnteFile> filteredFiles,
    required Map<int, List<Collection>> fileCollections,
  }) {
    if (!hasActiveFilters) {
      return List.from(widget.collections);
    }

    final availableIds = <int>{};

    for (final file in filteredFiles) {
      final fileId = file.uploadedFileID;
      if (fileId == null) {
        continue;
      }
      for (final collection in fileCollections[fileId] ?? const []) {
        availableIds.add(collection.id);
      }
    }

    if (availableIds.isEmpty && _selectedCollections.isNotEmpty) {
      for (final collection in _selectedCollections) {
        availableIds.add(collection.id);
      }
    }

    final ordered = <Collection>[];
    final seen = <int>{};

    for (final collection in widget.collections) {
      if (availableIds.contains(collection.id) && seen.add(collection.id)) {
        ordered.add(collection);
      }
    }

    for (final collection in _selectedCollections) {
      if (seen.add(collection.id)) {
        ordered.add(collection);
      }
    }

    return ordered;
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

  String _collectionLabel(Collection collection) {
    final name = collection.displayName?.trim();
    if (name == null || name.isEmpty) {
      return 'Untitled';
    }
    return name;
  }
}

class _FilterChipViewModel {
  const _FilterChipViewModel({
    required this.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String key;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.chips,
    required this.showClearButton,
    required this.onClearTapped,
  });

  final List<_FilterChipViewModel> chips;
  final bool showClearButton;
  final VoidCallback onClearTapped;

  @override
  Widget build(BuildContext context) {
    final listKey = chips.map((chip) => chip.key).join('-');
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: ListView.builder(
                key: ValueKey(listKey),
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                itemBuilder: (context, index) {
                  final chip = chips[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: chip.label,
                      isSelected: chip.isSelected,
                      onTap: chip.onTap,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
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
            child: showClearButton
                ? Padding(
                    key: const ValueKey('clear_button'),
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterClearButton(
                      onTap: onClearTapped,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no_clear_button')),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color:
                isSelected ? colorScheme.primary700 : colorScheme.backdropBase,
            borderRadius: const BorderRadius.all(Radius.circular(24.0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.small.copyWith(
                  color: isSelected ? Colors.white : colorScheme.textBase,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterClearButton extends StatelessWidget {
  const _FilterClearButton({
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
  });

  final VoidCallback onTap;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final accentColor = colorScheme.warning500;
    final backgroundColor = accentColor.withOpacity(0.12);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(24.0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              size: 16,
              color: accentColor,
            ),
            const SizedBox(width: 4),
            Text(
              context.l10n.clear,
              style: textTheme.small.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
