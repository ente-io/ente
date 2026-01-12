import "package:ente_ui/components/close_icon_button.dart";
import "package:ente_ui/theme/colors.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/text_style.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:hugeicons/hugeicons.dart";
import "package:locker/extensions/collection_extension.dart";
import 'package:locker/l10n/l10n.dart';
import "package:locker/models/selected_files.dart";
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import "package:locker/ui/components/empty_state_widget.dart";
import 'package:locker/ui/components/item_list_view.dart';
import 'package:locker/ui/pages/all_collections_page.dart';

class RecentsSectionWidget extends StatefulWidget {
  final List<Collection> collections;
  final List<EnteFile> recentFiles;
  final SelectedFiles? selectedFiles;
  final ValueNotifier<List<EnteFile>>? displayedFilesNotifier;

  const RecentsSectionWidget({
    super.key,
    required this.collections,
    required this.recentFiles,
    this.selectedFiles,
    this.displayedFilesNotifier,
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

  @override
  void initState() {
    super.initState();
    _originalCollectionOrder = List.from(widget.collections);
    _availableCollections = List.from(widget.collections);
    // Update notifier with initial displayed files after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDisplayedFilesNotifier();
    });
  }

  void _updateDisplayedFilesNotifier() {
    if (!mounted) return;
    widget.displayedFilesNotifier?.value = _displayedFiles;
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
      // Update notifier when source files change and no filters are active
      if (!_hasActiveFilters) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateDisplayedFilesNotifier();
        });
      }
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
        if (filterChipsRow != null) ...[
          filterChipsRow,
          const SizedBox(height: 16),
        ],
        _buildRecentsTable(context),
      ],
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
      onFilterIconTapped: () => _showFilterBottomSheet(context),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            final colorScheme = getEnteColorScheme(context);
            final textTheme = getEnteTextTheme(context);
            final orderedFilters = _getOrderedCollections();
            final chipModels = orderedFilters
                .map(
                  (collection) => _FilterChipViewModel(
                    key: 'c_${collection.id}',
                    label: _collectionLabel(collection),
                    isSelected: _selectedCollections.contains(collection),
                    onTap: () {
                      _onCollectionSelected(collection);
                      setBottomSheetState(() {});
                    },
                  ),
                )
                .toList();

            return _FilterBottomSheet(
              chips: chipModels,
              colorScheme: colorScheme,
              textTheme: textTheme,
              hasActiveFilters: _hasActiveFilters,
              onSeeAllCollections: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllCollectionsPage(),
                  ),
                );
              },
              onClearAllFilters: () {
                _clearAllFilters();
                setBottomSheetState(() {});
              },
              onClose: () => Navigator.pop(context),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentsTable(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOutExpo,
      switchOutCurve: Curves.easeInOutExpo,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: _displayedFiles.isEmpty
          ? EmptyStateWidget(
              key: const ValueKey('empty_state'),
              assetPath: "assets/empty_state.png",
              subtitle: context.l10n.noItemsMatchSelectedFilters,
            )
          : ItemListView(
              key: const ValueKey('items_list'),
              files: _displayedFiles,
              selectedFiles: widget.selectedFiles,
            ),
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

      // Update notifier when filters are cleared
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateDisplayedFilesNotifier();
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

    // Update notifier with the new displayed files
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDisplayedFilesNotifier();
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
    required this.onFilterIconTapped,
  });

  final List<_FilterChipViewModel> chips;
  final bool showClearButton;
  final VoidCallback onClearTapped;
  final VoidCallback onFilterIconTapped;

  @override
  Widget build(BuildContext context) {
    final listKey = chips.map((chip) => chip.key).join('-');
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          _FilterIconButton(
            onTap: onFilterIconTapped,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 8),
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
                      backgroundColor: colorScheme.backdropBase,
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

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({
    required this.onTap,
    required this.colorScheme,
  });

  final VoidCallback onTap;
  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.filter_list,
            color: colorScheme.textMuted,
            size: 24,
          ),
        ),
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
    required this.backgroundColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary700 : backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.small.copyWith(
                  color: isSelected ? Colors.white : colorScheme.textMuted,
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
    final backgroundColor = accentColor.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
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

class _FilterBottomSheet extends StatelessWidget {
  const _FilterBottomSheet({
    required this.chips,
    required this.colorScheme,
    required this.textTheme,
    required this.hasActiveFilters,
    required this.onSeeAllCollections,
    required this.onClearAllFilters,
    required this.onClose,
  });

  final List<_FilterChipViewModel> chips;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;
  final bool hasActiveFilters;
  final VoidCallback onSeeAllCollections;
  final VoidCallback onClearAllFilters;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              _ActionPillButton(
                label: context.l10n.seeAllCollections,
                onTap: onSeeAllCollections,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
              const Spacer(),
              _ActionPillButton(
                label: context.l10n.clearAllFilters,
                onTap: onClearAllFilters,
                showCloseIcon: true,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.backdropBase.withValues(alpha: 1.0),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              top: BorderSide(color: colorScheme.strokeFaint),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.filters,
                        style: textTheme.largeBold,
                      ),
                      const CloseIconButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: chips.map((chip) {
                          return _FilterChip(
                            label: chip.label,
                            isSelected: chip.isSelected,
                            onTap: chip.onTap,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            backgroundColor: colorScheme.backgroundElevated2,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  const _ActionPillButton({
    required this.label,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
    this.showCloseIcon = false,
  });

  final String label;
  final VoidCallback onTap;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;
  final bool showCloseIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated2,
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 10.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.small,
            ),
            if (showCloseIcon) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.close,
                color: colorScheme.textBase,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
