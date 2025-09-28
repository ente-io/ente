import "package:ente_ui/theme/colors.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/text_style.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/file_type.dart';
import 'package:locker/models/info/info_item.dart';
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
  final Set<InfoType> _selectedInfoTypes = {};
  final List<InfoType> _infoTypeSelectionOrder = [];
  List<EnteFile> _filteredFiles = [];
  List<Collection> _availableCollections = [];
  List<InfoType> _availableInfoTypes = InfoType.values.toList();
  late List<Collection> _originalCollectionOrder;
  int _filtersComputationId = 0;
  final Map<int, List<Collection>> _fileCollectionsCache = {};
  final Map<int, Future<List<Collection>>> _fileCollectionsRequests = {};
  final Map<int, InfoType?> _fileInfoTypeCache = {};

  @override
  void initState() {
    super.initState();
    _originalCollectionOrder = List.from(widget.collections);
    _availableCollections = List.from(widget.collections);
    _availableInfoTypes = _computeAvailableInfoTypes(widget.recentFiles);
  }

  @override
  void didUpdateWidget(RecentsSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recentFiles != widget.recentFiles ||
        oldWidget.collections != widget.collections) {
      _handleCollectionUpdates();
      setState(() {
        _originalCollectionOrder = List.from(widget.collections);
        if (!_hasActiveFilters) {
          _availableCollections = List.from(widget.collections);
        }
      });
      _updateFilteredFiles();
    }
  }

  bool get _hasActiveFilters =>
      _selectedCollections.isNotEmpty || _selectedInfoTypes.isNotEmpty;

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

  Widget? _buildFilterChipsRow() {
    final orderedFilters = _getOrderedFilters();

    if (orderedFilters.isEmpty) {
      return null;
    }

    final chipModels = orderedFilters
        .map(
          (filter) => _FilterChipViewModel(
            key: filter.key,
            label: filter.isCollection
                ? _collectionLabel(filter.collection!)
                : _infoTypeLabel(context, filter.infoType!),
            isSelected: filter.isCollection
                ? _selectedCollections.contains(filter.collection)
                : _selectedInfoTypes.contains(filter.infoType!),
            onTap: filter.isCollection
                ? () => _onCollectionSelected(filter.collection!)
                : () => _onInfoTypeSelected(filter.infoType!),
          ),
        )
        .toList();

    return _FilterChipsRow(
      chips: chipModels,
      showClearButton: _hasActiveFilters,
      onClearTapped: _clearAllFilters,
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
                'No items match the selected filters',
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
    );
  }

  List<_FilterChipEntry> _getOrderedFilters() {
    final filters = <_FilterChipEntry>[];

    for (final infoType in _getOrderedInfoTypes()) {
      filters.add(_FilterChipEntry.infoType(infoType));
    }

    for (final collection in _getOrderedCollections()) {
      filters.add(_FilterChipEntry.collection(collection));
    }

    return filters;
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

  void _onInfoTypeSelected(InfoType infoType) {
    HapticFeedback.lightImpact();

    setState(() {
      if (_selectedInfoTypes.contains(infoType)) {
        _selectedInfoTypes.remove(infoType);
        _infoTypeSelectionOrder.remove(infoType);
      } else {
        _selectedInfoTypes.add(infoType);
        _infoTypeSelectionOrder.add(infoType);
      }
    });

    _updateFilteredFiles();
  }

  void _clearAllFilters() {
    HapticFeedback.lightImpact();

    setState(() {
      _selectedCollections.clear();
      _selectionOrder.clear();
      _selectedInfoTypes.clear();
      _infoTypeSelectionOrder.clear();
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
    final hasInfoFilters = _selectedInfoTypes.isNotEmpty;
    final hasAnyFilters = hasCollectionFilters || hasInfoFilters;

    if (!hasAnyFilters) {
      final availableInfoTypes = _computeAvailableInfoTypes(widget.recentFiles);

      if (!mounted || computationId != _filtersComputationId) {
        return;
      }

      setState(() {
        _filteredFiles = [];
        _availableCollections = List.from(widget.collections);
        _availableInfoTypes = availableInfoTypes;
      });
      return;
    }

    final fileCollections =
        await _ensureCollectionsForFiles(widget.recentFiles);

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

      if (hasInfoFilters) {
        final infoType = _getInfoTypeForFile(file);
        if (infoType == null || !_selectedInfoTypes.contains(infoType)) {
          continue;
        }
      }

      filteredFiles.add(file);
      if (fileId != null) {
        filteredFileCollections[fileId] = collectionsForFile;
      }
    }

    final availableInfoTypes = _computeAvailableInfoTypes(filteredFiles);
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
      _availableInfoTypes = availableInfoTypes;
    });
  }

  Future<Map<int, List<Collection>>> _ensureCollectionsForFiles(
    List<EnteFile> files,
  ) async {
    final List<Future<void>> pending = [];

    for (final file in files) {
      final fileId = file.uploadedFileID;
      if (fileId == null) {
        continue;
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

  List<InfoType> _getOrderedInfoTypes() {
    final orderedInfoTypes = <InfoType>[];

    for (final infoType in _infoTypeSelectionOrder) {
      if (_availableInfoTypes.contains(infoType)) {
        orderedInfoTypes.add(infoType);
      }
    }

    for (final infoType in InfoType.values) {
      if (_availableInfoTypes.contains(infoType) &&
          !_selectedInfoTypes.contains(infoType)) {
        orderedInfoTypes.add(infoType);
      }
    }

    return orderedInfoTypes;
  }

  InfoType? _getInfoTypeForFile(EnteFile file) {
    if (file.fileType != FileType.info) {
      return null;
    }

    final fileId = file.uploadedFileID;
    if (fileId != null && _fileInfoTypeCache.containsKey(fileId)) {
      return _fileInfoTypeCache[fileId];
    }

    final infoData = file.pubMagicMetadata.info;
    if (infoData == null) {
      if (fileId != null) {
        _fileInfoTypeCache[fileId] = null;
      }
      return null;
    }

    final typeValue = infoData['type'];
    if (typeValue is! String) {
      if (fileId != null) {
        _fileInfoTypeCache[fileId] = null;
      }
      return null;
    }

    for (final infoType in InfoType.values) {
      if (infoType.name == typeValue) {
        if (fileId != null) {
          _fileInfoTypeCache[fileId] = infoType;
        }
        return infoType;
      }
    }

    try {
      final resolved = InfoTypeExtension.fromString(typeValue);
      if (fileId != null) {
        _fileInfoTypeCache[fileId] = resolved;
      }
      return resolved;
    } catch (_) {
      if (fileId != null) {
        _fileInfoTypeCache[fileId] = null;
      }
      return null;
    }
  }

  String _infoTypeLabel(BuildContext context, InfoType infoType) {
    final l10n = context.l10n;
    switch (infoType) {
      case InfoType.note:
        return l10n.personalNote;
      case InfoType.physicalRecord:
        return l10n.physicalRecords;
      case InfoType.accountCredential:
        return l10n.accountCredentials;
      case InfoType.emergencyContact:
        return l10n.emergencyContact;
    }
  }

  String _collectionLabel(Collection collection) {
    final name = collection.name?.trim();
    if (name == null || name.isEmpty) {
      return 'Untitled';
    }
    return name;
  }

  List<InfoType> _computeAvailableInfoTypes(List<EnteFile> baseFiles) {
    final typesInBase = <InfoType>{};

    for (final file in baseFiles) {
      final infoType = _getInfoTypeForFile(file);
      if (infoType != null) {
        typesInBase.add(infoType);
      }
    }

    final updatedInfoTypes = <InfoType>[];

    for (final infoType in _selectedInfoTypes) {
      if (!updatedInfoTypes.contains(infoType)) {
        updatedInfoTypes.add(infoType);
      }
    }

    for (final infoType in InfoType.values) {
      if (typesInBase.contains(infoType) &&
          !updatedInfoTypes.contains(infoType)) {
        updatedInfoTypes.add(infoType);
      }
    }

    return updatedInfoTypes;
  }
}

class _FilterChipEntry {
  const _FilterChipEntry.collection(this.collection) : infoType = null;

  const _FilterChipEntry.infoType(this.infoType) : collection = null;

  final Collection? collection;
  final InfoType? infoType;

  bool get isCollection => collection != null;

  String get key =>
      isCollection ? 'c_${collection!.id}' : 'i_${infoType!.name}';
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
      height: 40,
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.fillMuted : null,
            border: Border.all(
              color:
                  isSelected ? colorScheme.strokeBase : colorScheme.fillFaint,
              width: 1,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.mini,
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
                        key: const ValueKey('selected_chip'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onTap,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: colorScheme.strokeBase,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 10,
                                color: colorScheme.backdropBase,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('unselected_chip')),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.fillFaint,
          border: Border.all(
            color: colorScheme.strokeMuted,
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
              color: colorScheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              'Clear',
              style: textTheme.miniMuted,
            ),
          ],
        ),
      ),
    );
  }
}
