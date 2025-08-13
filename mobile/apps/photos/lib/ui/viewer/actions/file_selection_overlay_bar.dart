import "dart:io";

import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/hierarchical/only_them_filter.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/theme/effects.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/components/bottom_action_bar/bottom_action_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class FileSelectionOverlayBar extends StatefulWidget {
  static double roughHeight = Platform.isIOS ? 240.0 : 232.0;
  final GalleryType galleryType;
  final SelectedFiles selectedFiles;
  final Collection? collection;
  final Color? backgroundColor;
  final PersonEntity? person;
  final String? clusterID;

  const FileSelectionOverlayBar(
    this.galleryType,
    this.selectedFiles, {
    this.collection,
    this.backgroundColor,
    this.person,
    this.clusterID,
    super.key,
  });

  @override
  State<FileSelectionOverlayBar> createState() =>
      _FileSelectionOverlayBarState();
}

class _FileSelectionOverlayBarState extends State<FileSelectionOverlayBar> {
  final ValueNotifier<bool> _hasSelectedFilesNotifier = ValueNotifier(false);
  late GalleryType _galleryType;
  SearchFilterDataProvider? _searchFilterDataProvider;
  bool? _galleryInitialFilterStillApplied;

  @override
  void initState() {
    super.initState();
    _galleryType = widget.galleryType;
    widget.selectedFiles.addListener(_selectedFilesListener);
  }

  @override
  void dispose() {
    _hasSelectedFilesNotifier.dispose();
    widget.selectedFiles.removeListener(_selectedFilesListener);
    _searchFilterDataProvider?.removeListener(
      listener: _filterAppliedListener,
      fromApplied: true,
    );
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FileSelectionOverlayBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _galleryType = widget.galleryType;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inheritedSearchFilterData =
        InheritedSearchFilterData.maybeOf(context);
    if (inheritedSearchFilterData?.isHierarchicalSearchable ?? false) {
      _searchFilterDataProvider =
          inheritedSearchFilterData!.searchFilterDataProvider;

      _searchFilterDataProvider!.removeListener(
        listener: _filterAppliedListener,
        fromApplied: true,
      );
      _searchFilterDataProvider!.addListener(
        listener: _filterAppliedListener,
        toApplied: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '$runtimeType building with ${widget.selectedFiles.files.length}',
    );

    return _galleryType == GalleryType.homepage
        ? _body()
        : PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                if (widget.selectedFiles.files.isEmpty) {
                  Navigator.of(context).pop();
                }
                widget.selectedFiles.clearAll();
              }
            },
            child: _body(),
          );
  }

  Widget _body() {
    return ValueListenableBuilder(
      valueListenable: _hasSelectedFilesNotifier,
      builder: (context, value, child) {
        return AnimatedCrossFade(
          firstCurve: Curves.easeInOutExpo,
          secondCurve: Curves.easeInOutExpo,
          sizeCurve: Curves.easeInOutExpo,
          crossFadeState: _hasSelectedFilesNotifier.value
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 400),
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: SelectAllButton(
                  backgroundColor: widget.backgroundColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  boxShadow: shadowFloatFaintLight,
                ),
                child: BottomActionBarWidget(
                  selectedFiles: widget.selectedFiles,
                  galleryType: _galleryType,
                  collection: widget.collection,
                  person: widget.person,
                  clusterID: widget.clusterID,
                  onCancel: () {
                    if (widget.selectedFiles.files.isNotEmpty) {
                      widget.selectedFiles.clearAll();
                    }
                  },
                  backgroundColor: widget.backgroundColor,
                ),
              ),
            ],
          ),
          secondChild: const SizedBox(width: double.infinity),
        );
      },
    );
  }

  _selectedFilesListener() {
    _hasSelectedFilesNotifier.value = widget.selectedFiles.files.isNotEmpty;
  }

  void _filterAppliedListener() {
    widget.selectedFiles.clearAll();
    _updateGalleryTypeIfRequired();
  }

  /// This method is used to update the GalleryType if the initial filter is
  /// removed from the applied filters. As long as the inital filter is present
  /// in the applied filters, the gallery type will remain the same as the type
  /// initally passed in the widget constructor. Once the inital filter is
  /// removed, the gallery type will be updated to GalleryType.searchResults
  /// and never be updated again.
  void _updateGalleryTypeIfRequired() {
    if (_galleryInitialFilterStillApplied != null &&
        !_galleryInitialFilterStillApplied!) {
      return;
    }

    final appliedFilters = _searchFilterDataProvider!.appliedFilters;
    final initialFilter = _searchFilterDataProvider!.initialGalleryFilter;
    bool initalFilterIsInAppliedFiters = false;
    for (HierarchicalSearchFilter filter in appliedFilters) {
      if (filter.isSameFilter(initialFilter)) {
        initalFilterIsInAppliedFiters = true;
        break;
      }
      if (initialFilter is FaceFilter) {
        for (HierarchicalSearchFilter filter in appliedFilters) {
          if (filter is OnlyThemFilter) {
            if (filter.faceFilters
                .any((faceFilter) => faceFilter.isSameFilter(initialFilter))) {
              initalFilterIsInAppliedFiters = true;
              break;
            }
          }
        }
      }
    }

    if (!initalFilterIsInAppliedFiters) {
      setState(() {
        _galleryInitialFilterStillApplied = false;
        _galleryType = GalleryType.searchResults;
      });
    } else {
      _galleryInitialFilterStillApplied = true;
    }
  }
}

class SelectAllButton extends StatefulWidget {
  final Color? backgroundColor;
  const SelectAllButton({super.key, required this.backgroundColor});

  @override
  State<SelectAllButton> createState() => _SelectAllButtonState();
}

class _SelectAllButtonState extends State<SelectAllButton> {
  bool _allSelected = false;
  @override
  Widget build(BuildContext context) {
    final selectionState = SelectionState.of(context);
    final allGalleryFiles = GalleryFilesState.of(context).galleryFiles;
    assert(
      selectionState != null,
      "SelectionState not found in context, SelectionState should be an ancestor of FileSelectionOverlayBar",
    );
    final colorScheme = getEnteColorScheme(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_allSelected) {
            selectionState.selectedFiles.clearAll();
          } else {
            selectionState.selectedFiles.selectAll(
              allGalleryFiles.toSet(),
            );
          }
          _allSelected = !_allSelected;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? colorScheme.backgroundElevated2,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                S.of(context).selectAllShort,
                style: getEnteTextTheme(context).miniMuted,
              ),
              const SizedBox(width: 4),
              ListenableBuilder(
                listenable: selectionState!.selectedFiles,
                builder: (context, _) {
                  if (selectionState.selectedFiles.files.length ==
                      allGalleryFiles.length) {
                    _allSelected = true;
                  } else {
                    _allSelected = false;
                  }
                  return Icon(
                    _allSelected
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: _allSelected ? null : colorScheme.strokeMuted,
                    size: 18,
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
