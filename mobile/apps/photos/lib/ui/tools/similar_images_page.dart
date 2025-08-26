import "dart:async";

import "package:flutter/foundation.dart" show kDebugMode;
import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:logging/logging.dart';
import "package:photos/core/configuration.dart";
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/models/similar_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/machine_learning/similar_images_service.dart";
import "package:photos/theme/colors.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/theme/text_style.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/empty_state.dart";
import "package:photos/utils/delete_file_util.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/standalone/data.dart";

enum SimilarImagesPageState {
  setup,
  loading,
  results,
}

enum SortKey {
  size,
  distanceAsc,
  distanceDesc,
  count,
}

enum TabFilter {
  all,
  similar,
  identical,
}

class SimilarImagesPage extends StatefulWidget {
  final bool debugScreen;

  const SimilarImagesPage({super.key, this.debugScreen = false});

  @override
  State<SimilarImagesPage> createState() => _SimilarImagesPageState();
}

class _SimilarImagesPageState extends State<SimilarImagesPage> {
  static const crossAxisCount = 3;
  static const crossAxisSpacing = 12.0;
  static const double _similarThreshold = 0.02;
  static const double _identicalThreshold = 0.0001;

  final _logger = Logger("SimilarImagesPage");
  bool _isDisposed = false;

  SimilarImagesPageState _pageState = SimilarImagesPageState.setup;
  double _distanceThreshold = 0.04; // Default value
  List<SimilarFiles> _similarFilesList = [];

  SortKey _sortKey = SortKey.distanceAsc;
  bool _exactSearch = false;
  bool _fullRefresh = false;
  TabFilter _selectedTab = TabFilter.all;

  late SelectedFiles _selectedFiles;
  late ValueNotifier<String> _deleteProgress;

  List<SimilarFiles> get _filteredGroups {
    if (_selectedTab == TabFilter.all) {
      return _similarFilesList;
    }

    final threshold = _selectedTab == TabFilter.similar
        ? _similarThreshold
        : _identicalThreshold;

    return _similarFilesList.where((group) {
      return group.furthestDistance <= threshold;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedFiles = SelectedFiles();
    _deleteProgress = ValueNotifier("");

    if (!widget.debugScreen) {
      _findSimilarImages();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _selectedFiles.dispose();
    _deleteProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(AppLocalizations.of(context).similarImages),
        actions: _pageState == SimilarImagesPageState.results
            ? [_getSortMenu()]
            : null,
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    final content = switch (_pageState) {
      SimilarImagesPageState.setup => _getSetupView(),
      SimilarImagesPageState.loading => _getLoadingView(),
      SimilarImagesPageState.results => _getResultsView(),
    };

    return Stack(
      children: [
        content,
        // Progress overlay
        ValueListenableBuilder(
          valueListenable: _deleteProgress,
          builder: (context, value, child) {
            if (value.isEmpty) {
              return const SizedBox.shrink();
            }

            final colorScheme = getEnteColorScheme(context);
            final textTheme = getEnteTextTheme(context);

            return Container(
              color: colorScheme.backgroundBase.withValues(alpha: 0.8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.backgroundElevated,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.strokeFaint,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(colorScheme.primary500),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)
                            .deletingProgress(progress: value),
                        style: textTheme.body,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _getSetupView() {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 72,
            color: colorScheme.primary500,
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context).findSimilarImages,
            style: textTheme.h3Bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Use AI to find images that look similar to each other. Adjust the distance threshold below.",
            style: textTheme.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Text(
            "Similarity threshold",
            style: textTheme.bodyBold,
          ),
          const SizedBox(height: 8),
          Text(
            "Lower values mean a closer match.",
            style: textTheme.miniMuted,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                "0.01",
                style: textTheme.mini,
              ),
              Expanded(
                child: Slider(
                  value: _distanceThreshold,
                  min: 0.01,
                  max: 0.15,
                  divisions: 14,
                  onChanged: (value) {
                    if (_isDisposed) return;
                    setState(() {
                      _distanceThreshold = (value * 100).round() / 100;
                    });
                  },
                ),
              ),
              Text(
                "0.15",
                style: textTheme.mini,
              ),
            ],
          ),
          Text(
            "Current: ${_distanceThreshold.toStringAsFixed(2)}",
            style: textTheme.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Exact search",
                style: textTheme.bodyBold,
              ),
              ToggleSwitchWidget(
                value: () => _exactSearch,
                onChanged: () async {
                  if (_isDisposed) return;
                  setState(() {
                    _exactSearch = !_exactSearch;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Full refresh",
                style: textTheme.bodyBold,
              ),
              ToggleSwitchWidget(
                value: () => _fullRefresh,
                onChanged: () async {
                  if (_isDisposed) return;
                  setState(() {
                    _fullRefresh = !_fullRefresh;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          ButtonWidget(
            labelText: AppLocalizations.of(context).findSimilarImages,
            buttonType: ButtonType.primary,
            onTap: () async {
              await _findSimilarImages();
            },
          ),
        ],
      ),
    );
  }

  Widget _getLoadingView() {
    return const SimilarImagesLoadingWidget();
  }

  Widget _getResultsView() {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    if (_similarFilesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: colorScheme.primary500,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noSimilarImagesFound,
              style: textTheme.h3Bold,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).yourPhotosLookUnique,
              style: textTheme.bodyMuted,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: _filteredGroups.isEmpty
              ? const EmptyState()
              : ListView.builder(
                  cacheExtent: 400,
                  itemCount: _filteredGroups.length,
                  itemBuilder: (context, index) {
                    final similarFiles = _filteredGroups[index];
                    return RepaintBoundary(
                      child: _buildSimilarFilesGroup(similarFiles),
                    );
                  },
                ),
        ),
        if (_filteredGroups.isNotEmpty) _getBottomActionButtons(),
      ],
    );
  }

  Widget _buildTabBar() {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildTabButton(
            TabFilter.all,
            AppLocalizations.of(context).all,
            colorScheme,
            textTheme,
          ),
          const SizedBox(width: crossAxisSpacing),
          _buildTabButton(
            TabFilter.similar,
            AppLocalizations.of(context).similar,
            colorScheme,
            textTheme,
          ),
          const SizedBox(width: crossAxisSpacing),
          _buildTabButton(
            TabFilter.identical,
            AppLocalizations.of(context).identical,
            colorScheme,
            textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    TabFilter tab,
    String label,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final isSelected = _selectedTab == tab;

    return GestureDetector(
      onTap: () => _onTabChanged(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary700 : colorScheme.fillFaint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: isSelected
              ? textTheme.smallBold.copyWith(color: Colors.white)
              : textTheme.smallBold,
        ),
      ),
    );
  }

  void _onTabChanged(TabFilter newTab) {
    setState(() {
      _selectedTab = newTab;

      final newSelection = <EnteFile>{};
      for (final group in _filteredGroups) {
        for (int i = 1; i < group.files.length; i++) {
          newSelection.add(group.files[i]);
        }
      }
      _selectedFiles.clearAll();
      _selectedFiles.selectAll(newSelection);
    });
  }

  Widget _getBottomActionButtons() {
    return ListenableBuilder(
      listenable: _selectedFiles,
      builder: (context, _) {
        final selectedFiles = _selectedFiles.files;
        final selectedCount = selectedFiles.length;
        final hasSelectedFiles = selectedCount > 0;

        final eligibleFilteredFiles = <EnteFile>{};
        for (final group in _filteredGroups) {
          for (int i = 1; i < group.files.length; i++) {
            eligibleFilteredFiles.add(group.files[i]);
          }
        }

        final selectedFilteredFiles =
            selectedFiles.intersection(eligibleFilteredFiles);
        final allFilteredSelected = eligibleFilteredFiles.isNotEmpty &&
            selectedFilteredFiles.length == eligibleFilteredFiles.length;

        int totalSize = 0;
        for (final file in selectedFilteredFiles) {
          totalSize += file.fileSize ?? 0;
        }

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: crossAxisSpacing,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: getEnteColorScheme(context).backgroundBase,
            ),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: hasSelectedFiles
                      ? Column(
                          key: const ValueKey('delete_section'),
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ButtonWidget(
                                labelText: AppLocalizations.of(context)
                                    .deletePhotosWithSize(
                                  count: NumberFormat().format(selectedFilteredFiles.length),
                                  size: formatBytes(totalSize),
                                ),
                                buttonType: ButtonType.critical,
                                shouldSurfaceExecutionStates: false,
                                shouldShowSuccessConfirmation: false,
                                onTap: () async {
                                  await _deleteFiles(
                                    selectedFilteredFiles,
                                    showDialog: true,
                                    showUIFeedback: true,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey('no_delete')),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ButtonWidget(
                    labelText: allFilteredSelected
                        ? AppLocalizations.of(context).unselectAll
                        : AppLocalizations.of(context).selectAll,
                    buttonType: ButtonType.secondary,
                    shouldSurfaceExecutionStates: false,
                    shouldShowSuccessConfirmation: false,
                    onTap: () async {
                      _toggleSelectAll();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleSelectAll() {
    final eligibleFiles = <EnteFile>{};
    for (final group in _filteredGroups) {
      for (int i = 1; i < group.files.length; i++) {
        eligibleFiles.add(group.files[i]);
      }
    }

    final currentSelected = _selectedFiles.files.intersection(eligibleFiles);
    final allSelected = eligibleFiles.isNotEmpty &&
        currentSelected.length == eligibleFiles.length;

    if (allSelected) {
      _selectedFiles.unSelectAll(eligibleFiles);
    } else {
      _selectedFiles.selectAll(eligibleFiles);
    }
  }

  Future<void> _findSimilarImages() async {
    if (_isDisposed) return;
    setState(() {
      _pageState = SimilarImagesPageState.loading;
    });

    try {
      _logger.info("exact mode: $_exactSearch");

      final similarFiles = await SimilarImagesService.instance.getSimilarFiles(
        _distanceThreshold,
        exact: _exactSearch,
        forceRefresh: _fullRefresh,
      );
      _logger.info(
        "Found ${similarFiles.length} groups of similar images",
      );

      _similarFilesList = similarFiles;
      _pageState = SimilarImagesPageState.results;
      _sortSimilarFiles();

      for (final group in _similarFilesList) {
        if (group.files.length > 1) {
          for (int i = 1; i < group.files.length; i++) {
            _selectedFiles.toggleSelection(group.files[i]);
          }
        }
      }

      if (_isDisposed) return;
      setState(() {});

      return;
    } catch (e, s) {
      _logger.severe("Failed to get similar files", e, s);
      if (_isDisposed) return;
      if (flagService.internalUser) {
        await showGenericErrorDialog(context: context, error: e);
      }
      if (_isDisposed) return;
      setState(() {
        _pageState = SimilarImagesPageState.setup;
      });
      return;
    }
  }

  void _sortSimilarFiles() {
    switch (_sortKey) {
      case SortKey.size:
        _similarFilesList.sort((a, b) => b.totalSize.compareTo(a.totalSize));
        break;
      case SortKey.distanceAsc:
        _similarFilesList.sort((a, b) {
          final distanceComparison =
              a.furthestDistance.compareTo(b.furthestDistance);
          if (distanceComparison != 0) {
            return distanceComparison;
          }
          return b.totalSize.compareTo(a.totalSize);
        });
        break;
      case SortKey.distanceDesc:
        _similarFilesList.sort((a, b) {
          final distanceComparison =
              b.furthestDistance.compareTo(a.furthestDistance);
          if (distanceComparison != 0) {
            return distanceComparison;
          }
          return b.totalSize.compareTo(a.totalSize);
        });
        break;
      case SortKey.count:
        _similarFilesList
            .sort((a, b) => b.files.length.compareTo(a.files.length));
        break;
    }
    if (_isDisposed) return;
    setState(() {});
  }

  Widget _buildSimilarFilesGroup(SimilarFiles similarFiles) {
    final textTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: crossAxisSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)
                        .similarImagesCount(count: similarFiles.files.length) +
                    (kDebugMode
                        ? " (I: d: ${similarFiles.furthestDistance.toStringAsFixed(3)})"
                        : ""),
                style: textTheme.smallMuted.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 34,
                child: ListenableBuilder(
                  listenable: _selectedFiles,
                  builder: (context, _) {
                    final groupSelectedFiles = similarFiles.files
                        .where((file) => _selectedFiles.isFileSelected(file))
                        .toSet();
                    final bool allFilesFromGroupSelected =
                        groupSelectedFiles.length == similarFiles.length;
                    if (groupSelectedFiles.isNotEmpty) {
                      return _getSmallDeleteButton(
                        groupSelectedFiles,
                        allFilesFromGroupSelected,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth -
                      (crossAxisSpacing * (crossAxisCount - 1))) /
                  crossAxisCount;
              final itemHeight =
                  itemWidth / 0.70; // Maintain aspect ratio from GridView

              return Wrap(
                spacing: crossAxisSpacing,
                runSpacing:
                    0, // No additional vertical spacing - items have internal bottom padding
                children: similarFiles.files.asMap().entries.map((entry) {
                  return SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: _buildFile(
                      context,
                      entry.value,
                      similarFiles.files,
                      entry.key,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16), // Add spacing between groups
        ],
      ),
    );
  }

  Widget _buildFile(
    BuildContext context,
    EnteFile file,
    List<EnteFile> allFiles,
    int index,
  ) {
    final textTheme = getEnteTextTheme(context);
    return ListenableBuilder(
      listenable: _selectedFiles,
      builder: (context, _) {
        final bool isSelected = _selectedFiles.isFileSelected(file);

        return GestureDetector(
          onTap: () {
            _selectedFiles.toggleSelection(file);
          },
          onLongPress: () {
            routeToPage(
              context,
              DetailPage(
                DetailPageConfiguration(
                  allFiles,
                  index,
                  "similar_images_",
                  mode: DetailPageMode.minimalistic,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Hero(
                      tag: "similar_images_" + file.tag,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: isSelected
                            ? ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withAlpha((0.4 * 255).toInt()),
                                  BlendMode.darken,
                                ),
                                child: ThumbnailWidget(
                                  file,
                                  diskLoadDeferDuration:
                                      galleryThumbnailDiskLoadDeferDuration,
                                  serverLoadDeferDuration:
                                      galleryThumbnailServerLoadDeferDuration,
                                  shouldShowLivePhotoOverlay: true,
                                  key: Key("similar_images_" + file.tag),
                                ),
                              )
                            : ThumbnailWidget(
                                file,
                                diskLoadDeferDuration:
                                    galleryThumbnailDiskLoadDeferDuration,
                                serverLoadDeferDuration:
                                    galleryThumbnailServerLoadDeferDuration,
                                shouldShowLivePhotoOverlay: true,
                                key: Key("similar_images_" + file.tag),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 22,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                file.displayName,
                style: textTheme.small,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                formatBytes(file.fileSize!),
                style: textTheme.miniMuted,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _getSmallDeleteButton(Set<EnteFile> files, bool showDialog) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () async {
        await _deleteFiles(
          files,
          showDialog: showDialog,
          showUIFeedback: false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.warning500.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: 12,
              color: colorScheme.warning500,
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context).deleteWithCount(count: files.length),
              style: textTheme.smallBold.copyWith(
                color: colorScheme.warning500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFiles(
    Set<EnteFile> filesToDelete, {
    bool showDialog = true,
    bool showUIFeedback = true,
  }) async {
    if (filesToDelete.isEmpty) return;
    if (showDialog) {
      final _ = await showChoiceActionSheet(
        context,
        title: AppLocalizations.of(context).deleteFiles,
        body: AppLocalizations.of(context).areYouSureDeleteFiles,
        firstButtonLabel: AppLocalizations.of(context).delete,
        isCritical: true,
        firstButtonOnTap: () async {
          try {
            await _deleteFilesLogic(
              filesToDelete,
              true,
              showUIFeedback: showUIFeedback,
            );
          } catch (e, s) {
            _logger.severe("Failed to delete files", e, s);
            if (flagService.internalUser) {
              await showGenericErrorDialog(context: context, error: e);
            }
          }
        },
      );
    } else {
      await _deleteFilesLogic(
        filesToDelete,
        true,
        showUIFeedback: showUIFeedback,
      );
    }
  }

  Future<void> _deleteFilesLogic(
    Set<EnteFile> filesToDelete,
    bool createSymlink, {
    bool showUIFeedback = true,
  }) async {
    if (filesToDelete.isEmpty) {
      return;
    }
    final Map<int, Set<EnteFile>> collectionToFilesToAddMap = {};
    final allDeleteFiles = <EnteFile>{};
    final groupsToRemove = <SimilarFiles>{};
    for (final similarGroup in _similarFilesList) {
      final groupDeleteFiles = <EnteFile>{};
      for (final file in filesToDelete) {
        if (similarGroup.containsFile(file)) {
          similarGroup.removeFile(file);
          groupDeleteFiles.add(file);
          allDeleteFiles.add(file);
          if (similarGroup.isEmpty) {
            break;
          }
        }
      }
      if (similarGroup.length <= 1) {
        groupsToRemove.add(similarGroup);
      }
      if (groupDeleteFiles.isNotEmpty) {
        filesToDelete.removeAll(groupDeleteFiles);
      }
      if (!similarGroup.isEmpty && createSymlink) {
        final filesToKeep = similarGroup.files;
        final collectionIDs =
            filesToKeep.map((file) => file.collectionID).toSet();
        for (final deletedFile in groupDeleteFiles) {
          final collectionID = deletedFile.collectionID;
          if (collectionIDs.contains(collectionID) || collectionID == null) {
            continue;
          }
          if (!collectionToFilesToAddMap.containsKey(collectionID)) {
            collectionToFilesToAddMap[collectionID] = {};
          }
          collectionToFilesToAddMap[collectionID]!.addAll(filesToKeep);
        }
      }
    }
    for (final group in groupsToRemove) {
      _similarFilesList.remove(group);
    }

    final int collectionCnt = collectionToFilesToAddMap.keys.length;
    if (createSymlink) {
      final userID = Configuration.instance.getUserID();
      int progress = 0;
      for (final collectionID in collectionToFilesToAddMap.keys) {
        if (!mounted) {
          return;
        }
        if (collectionCnt > 2 && showUIFeedback) {
          progress++;
          // calculate progress percentage upto 2 decimal places
          final double percentage = (progress / collectionCnt) * 100;
          _deleteProgress.value = '${percentage.toStringAsFixed(1)}%';
        }
        // Check permission before attempting to add symlinks
        final collection =
            CollectionsService.instance.getCollectionByID(collectionID);
        if (collection != null && collection.canAutoAdd(userID!)) {
          await CollectionsService.instance.addSilentlyToCollection(
            collectionID,
            collectionToFilesToAddMap[collectionID]!.toList(),
          );
        } else {
          _logger.warning(
            "Skipping adding symlinks to collection $collectionID due to missing permissions (${collection?.canAutoAdd(userID!) ?? false}) or collection not found. (${collection == null})",
          );
        }
      }
    }
    if (collectionCnt > 2 && showUIFeedback) {
      _deleteProgress.value = "";
    }

    _selectedFiles.unSelectAll(allDeleteFiles);
    setState(() {});
    await deleteFilesFromRemoteOnly(context, allDeleteFiles.toList());

    // Show congratulations popup
    if (allDeleteFiles.length > 100 && mounted && showUIFeedback) {
      final int totalSize = allDeleteFiles.fold<int>(
        0,
        (sum, file) => sum + (file.fileSize ?? 0),
      );
      _showCongratulationsDialog(allDeleteFiles.length, totalSize);
    }
  }

  void _showCongratulationsDialog(int deletedCount, int totalSize) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.backgroundElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration_outlined,
              size: 48,
              color: colorScheme.primary500,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).greatJob,
              style: textTheme.h3Bold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).cleanedUpSimilarImages(
                count: deletedCount,
                size: formatBytes(totalSize),
              ),
              style: textTheme.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ButtonWidget(
                labelText: AppLocalizations.of(context).done,
                buttonType: ButtonType.primary,
                onTap: () async => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSortMenu() {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    Text sortOptionText(SortKey key) {
      String text;
      switch (key) {
        case SortKey.size:
          text = AppLocalizations.of(context).size;
          break;
        case SortKey.distanceAsc:
          text = AppLocalizations.of(context).similarity;
          break;
        case SortKey.distanceDesc:
          text = "(I) Similarity ↑";
          break;
        case SortKey.count:
          text = AppLocalizations.of(context).count;
          break;
      }
      return Text(
        text,
        style: textTheme.miniBold,
      );
    }

    return PopupMenuButton(
      initialValue: _sortKey.index,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
        child: Icon(
          Icons.sort,
          color: colorScheme.strokeBase,
          size: 20,
        ),
      ),
      onSelected: (int index) {
        if (_isDisposed) return;
        setState(() {
          final newKey = SortKey.values[index];
          if (newKey == _sortKey) {
            return;
          } else {
            _sortKey = newKey;
          }
        });
        _sortSimilarFiles();
      },
      itemBuilder: (context) {
        final sortKeys = kDebugMode
            ? SortKey.values
            : SortKey.values
                .where((key) => key != SortKey.distanceDesc)
                .toList();
        return List.generate(sortKeys.length, (index) {
          final sortKey = sortKeys[index];
          return PopupMenuItem(
            value: SortKey.values.indexOf(sortKey),
            child: Text(
              sortOptionText(sortKey).data!,
              style: textTheme.miniBold,
            ),
          );
        });
      },
    );
  }
}

class SimilarImagesLoadingWidget extends StatefulWidget {
  const SimilarImagesLoadingWidget({super.key});

  @override
  State<SimilarImagesLoadingWidget> createState() =>
      _SimilarImagesLoadingWidgetState();
}

class _SimilarImagesLoadingWidgetState extends State<SimilarImagesLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _loadingAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  int _loadingMessageIndex = 0;

  List<String> get _loadingMessages => [
        AppLocalizations.of(context).analyzingPhotosLocally,
        AppLocalizations.of(context).lookingForVisualSimilarities,
        AppLocalizations.of(context).comparingImageDetails,
        AppLocalizations.of(context).findingSimilarImages,
        AppLocalizations.of(context).almostDone,
      ];

  @override
  void initState() {
    super.initState();

    // Initialize loading animations
    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _startMessageCycling();
  }

  void _startMessageCycling() {
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(const Duration(seconds: 7));
      if (mounted) {
        setState(() {
          _loadingMessageIndex++;
        });
        // Stop cycling after reaching the last message
        return _loadingMessageIndex < _loadingMessages.length - 1;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated scanning effect
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing background circle
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary500.withValues(
                        alpha: _pulseAnimation.value * 0.1,
                      ),
                    ),
                  );
                },
              ),
              // Rotating scanner ring
              AnimatedBuilder(
                animation: _loadingAnimationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _loadingAnimationController.value * 2 * 3.14159,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary500,
                          width: 2,
                        ),
                        gradient: SweepGradient(
                          colors: [
                            colorScheme.primary500.withValues(alpha: 0),
                            colorScheme.primary500.withValues(alpha: 0.3),
                            colorScheme.primary500.withValues(alpha: 0.6),
                            colorScheme.primary500,
                            colorScheme.primary500.withValues(alpha: 0),
                          ],
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Center icon with scale animation
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.backgroundElevated,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.strokeFaint,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.photo_library_outlined,
                        size: 40,
                        color: colorScheme.primary500,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 48),
          // Privacy badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.fillFaint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: colorScheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).processingLocally,
                  style: textTheme.miniFaint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Animated loading message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _loadingMessages[_loadingMessageIndex],
              key: ValueKey(_loadingMessageIndex),
              style: textTheme.body,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          // Progress dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (index) => AnimatedBuilder(
                animation: _loadingAnimationController,
                builder: (context, child) {
                  final delay = index * 0.2;
                  final value =
                      (_loadingAnimationController.value + delay) % 1.0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary500.withValues(
                        alpha: value < 0.5 ? value * 2 : 2 - value * 2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
