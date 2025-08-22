import "dart:async";

import "package:flutter/foundation.dart" show kDebugMode;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";

import "package:photos/models/file/file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/models/similar_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/machine_learning/similar_images_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

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

class SimilarImagesPage extends StatefulWidget {
  final bool debugScreen;

  const SimilarImagesPage({super.key, this.debugScreen = false});

  @override
  State<SimilarImagesPage> createState() => _SimilarImagesPageState();
}

class _SimilarImagesPageState extends State<SimilarImagesPage> {
  static const crossAxisCount = 3;
  static const crossAxisSpacing = 12.0;

  final _logger = Logger("SimilarImagesPage");
  bool _isDisposed = false;

  SimilarImagesPageState _pageState = SimilarImagesPageState.setup;
  double _distanceThreshold = 0.04; // Default value
  List<SimilarFiles> _similarFilesList = [];
  SortKey _sortKey = SortKey.distanceAsc;
  bool _exactSearch = false;
  bool _fullRefresh = false;
  bool _isSelectionSheetOpen = false;

  late SelectedFiles _selectedFiles;
  late ValueNotifier<String> _deleteProgress;

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
        title: const Text("Similar images"), // TODO: lau: extract string
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
              color: colorScheme.backgroundBase.withOpacity(0.8),
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
                        "Deleting... $value", // TODO: lau: extract string
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
            "Find similar images", // TODO: lau: extract string
            style: textTheme.h3Bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Use AI to find images that look similar to each other. Adjust the distance threshold below.", // TODO: lau: extract string
            style: textTheme.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Text(
            "Similarity threshold", // TODO: lau: extract string
            style: textTheme.bodyBold,
          ),
          const SizedBox(height: 8),
          Text(
            "Lower values mean a closer match.", // TODO: lau: extract string
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
            "Current: ${_distanceThreshold.toStringAsFixed(2)}", // TODO: lau: extract string
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
            labelText: "Find similar images", // TODO: lau: extract string
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
              "No similar images found", // TODO: lau: extract string
              style: textTheme.h3Bold,
            ),
            const SizedBox(height: 8),
            Text(
              "Your photos look unique", // TODO: lau: extract string
              style: textTheme.bodyMuted,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            cacheExtent: 400,
            itemCount: _similarFilesList.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return RepaintBoundary(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: crossAxisSpacing,
                      vertical: 12,
                    ),
                    padding: const EdgeInsets.all(crossAxisSpacing),
                    decoration: BoxDecoration(
                      color: colorScheme.fillFaint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 20,
                          color: colorScheme.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${_similarFilesList.length} ${_similarFilesList.length == 1 ? 'group' : 'groups'} found", // TODO: lau: extract string
                                style: textTheme.bodyBold,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Review and remove similar images", // TODO: lau: extract string
                                style: textTheme.miniMuted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Similar files groups (index - 1 because first item is header)
              final similarFiles = _similarFilesList[index - 1];
              return RepaintBoundary(
                child: _buildSimilarFilesGroup(similarFiles),
              );
            },
          ),
        ),
        _getBottomActionButtons(),
      ],
    );
  }

  Widget _getBottomActionButtons() {
    return ListenableBuilder(
      listenable: _selectedFiles,
      builder: (context, _) {
        final selectedCount = _selectedFiles.files.length;
        final hasSelectedFiles = selectedCount > 0;

        int totalSize = 0;
        for (final file in _selectedFiles.files) {
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
                  child: hasSelectedFiles && !_isSelectionSheetOpen
                      ? Column(
                          key: const ValueKey('delete_section'),
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ButtonWidget(
                                labelText:
                                    "Delete $selectedCount photos (${formatBytes(totalSize)})", // TODO: lau: extract string
                                buttonType: ButtonType.critical,
                                shouldSurfaceExecutionStates: false,
                                shouldShowSuccessConfirmation: false,
                                onTap: () async {
                                  await _deleteFiles(
                                    _selectedFiles.files,
                                    showDialog: true,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey('no_delete')),
                ),
                if (!_isSelectionSheetOpen)
                  SizedBox(
                    width: double.infinity,
                    child: ButtonWidget(
                      labelText:
                          "Selection options", // TODO: lau: extract string
                      buttonType: ButtonType.secondary,
                      shouldSurfaceExecutionStates: false,
                      shouldShowSuccessConfirmation: false,
                      onTap: () async {
                        setState(() {
                          _isSelectionSheetOpen = true;
                        });
                        await _showSelectionOptionsSheet();
                        if (mounted) {
                          setState(() {
                            _isSelectionSheetOpen = false;
                          });
                        }
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

  Future<void> _findSimilarImages() async {
    if (_isDisposed) return;
    setState(() {
      _pageState = SimilarImagesPageState.loading;
    });

    try {
      // You can use _toggleValue here for advanced mode features
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

  void _selectFilesByThreshold(double threshold) {
    final filesToSelect = <EnteFile>{};

    for (final similarFilesGroup in _similarFilesList) {
      if (similarFilesGroup.furthestDistance <= threshold) {
        for (int i = 1; i < similarFilesGroup.files.length; i++) {
          filesToSelect.add(similarFilesGroup.files[i]);
        }
      }
    }

    if (filesToSelect.isNotEmpty) {
      _selectedFiles.clearAll(fireEvent: false);
      _selectedFiles.selectAll(filesToSelect);
    } else {
      _selectedFiles.clearAll(fireEvent: false);
    }
  }

  Future<void> _showSelectionOptionsSheet() async {
    // Calculate how many files fall into each category
    int exactFiles = 0;
    int similarFiles = 0;
    int allFiles = 0;

    for (final group in _similarFilesList) {
      final duplicateCount = group.files.length - 1; // Exclude the first file
      allFiles += duplicateCount;

      if (group.furthestDistance <= 0.0) {
        exactFiles += duplicateCount;
        similarFiles += duplicateCount;
      } else if (group.furthestDistance <= 0.02) {
        similarFiles += duplicateCount;
      }
    }

    final String exactLabel = exactFiles > 0
        ? "Select exact ($exactFiles)" // TODO: lau: extract string
        : "Select exact"; // TODO: lau: extract string

    final String similarLabel = similarFiles > 0
        ? "Select similar ($similarFiles)" // TODO: lau: extract string
        : "Select similar"; // TODO: lau: extract string

    final String allLabel = allFiles > 0
        ? "Select all ($allFiles)" // TODO: lau: extract string
        : "Select all"; // TODO: lau: extract string

    await showActionSheet(
      context: context,
      title: "Select similar images", // TODO: lau: extract string
      body:
          "Choose which similar images to select for deletion", // TODO: lau: extract string
      buttons: [
        ButtonWidget(
          labelText: exactLabel,
          buttonType: ButtonType.neutral,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          isInAlert: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: false,
          onTap: () async {
            _selectFilesByThreshold(0.0);
          },
        ),
        ButtonWidget(
          labelText: similarLabel,
          buttonType: ButtonType.neutral,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          isInAlert: true,
          buttonAction: ButtonAction.second,
          shouldSurfaceExecutionStates: false,
          onTap: () async {
            _selectFilesByThreshold(0.02);
          },
        ),
        ButtonWidget(
          labelText: allLabel,
          buttonType: ButtonType.neutral,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          isInAlert: true,
          buttonAction: ButtonAction.third,
          shouldSurfaceExecutionStates: false,
          onTap: () async {
            _selectFilesByThreshold(0.05);
          },
        ),
        ButtonWidget(
          labelText: "Clear selection", // TODO: lau: extract string
          buttonType: ButtonType.secondary,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          isInAlert: true,
          buttonAction: ButtonAction.cancel,
          shouldSurfaceExecutionStates: false,
          onTap: () async {
            _selectedFiles.clearAll(fireEvent: false);
          },
        ),
      ],
      actionSheetType: ActionSheetType.defaultActionSheet,
    );
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
                "${similarFiles.files.length} similar images" +
                    (kDebugMode
                        ? " (I: d: ${similarFiles.furthestDistance.toStringAsFixed(3)})"
                        : ""), // TODO: lau: extract string
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
        final bool hasAnySelection = _selectedFiles.files.isNotEmpty;

        return GestureDetector(
          onTap: () {
            if (hasAnySelection) {
              // If files are selected, tap should toggle selection
              _selectedFiles.toggleSelection(file);
            } else {
              // If no files selected, tap opens detail page
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
            }
          },
          onLongPress: () {
            if (hasAnySelection) {
              // If files are selected, long press opens detail page
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
            } else {
              // If no files selected, long press starts selection
              _selectedFiles.toggleSelection(file);
            }
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
        await _deleteFiles(files, showDialog: showDialog);
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
              "Delete (${files.length})", // TODO: lau: extract string
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
  }) async {
    if (filesToDelete.isEmpty) return;
    if (showDialog) {
      final _ = await showChoiceActionSheet(
        context,
        title: "Delete files", // TODO: lau: extract string
        body:
            "Are you sure you want to delete these files?", // TODO: lau: extract string
        firstButtonLabel: AppLocalizations.of(context).delete,
        isCritical: true,
        firstButtonOnTap: () async {
          try {
            await _deleteFilesLogic(filesToDelete, true);
          } catch (e, s) {
            _logger.severe("Failed to delete files", e, s);
            if (flagService.internalUser) {
              await showGenericErrorDialog(context: context, error: e);
            }
          }
        },
      );
    } else {
      await _deleteFilesLogic(filesToDelete, true);
    }
  }

  Future<void> _deleteFilesLogic(
    Set<EnteFile> filesToDelete,
    bool createSymlink,
  ) async {
    if (filesToDelete.isEmpty) {
      return;
    }
    final Map<int, List<EnteFile>> collectionToFilesToAddMap = {};
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
      if (similarGroup.files.length <= 1) {
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
            collectionToFilesToAddMap[collectionID] = [];
          }
          collectionToFilesToAddMap[collectionID]!.addAll(filesToKeep);
        }
      }
    }
    for (final group in groupsToRemove) {
      _similarFilesList.remove(group);
    }

    if (createSymlink) {
      final int collectionCnt = collectionToFilesToAddMap.keys.length;
      int progress = 0;
      for (final collectionID in collectionToFilesToAddMap.keys) {
        if (!mounted) {
          return;
        }
        if (collectionCnt > 0) {
          progress++;
          // calculate progress percentage upto 2 decimal places
          final double percentage = (progress / collectionCnt) * 100;
          _deleteProgress.value = '${percentage.toStringAsFixed(1)}%';
        }
        await CollectionsService.instance.addSilentlyToCollection(
          collectionID,
          collectionToFilesToAddMap[collectionID]!,
        );
      }
    }
    _deleteProgress.value = "";

    _selectedFiles.unSelectAll(allDeleteFiles);
    setState(() {});
    await deleteFilesFromRemoteOnly(context, allDeleteFiles.toList());

    // Show congratulations popup
    if (allDeleteFiles.isNotEmpty && mounted) {
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
              "Great job!", // TODO: lau: extract string
              style: textTheme.h3Bold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "You cleaned up $deletedCount similar ${deletedCount == 1 ? 'image' : 'images'} and freed up ${formatBytes(totalSize)}", // TODO: lau: extract string
              style: textTheme.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ButtonWidget(
                labelText: "Done", // TODO: lau: extract string
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

    Widget sortOptionContent(SortKey key) {
      String text;
      Widget trailing;

      switch (key) {
        case SortKey.size:
          text = "Size"; // TODO: lau: extract string
          trailing = Icon(
            Icons.arrow_downward,
            size: 16,
            color: colorScheme.textMuted,
          );
          break;
        case SortKey.distanceAsc:
          text = "Similarity"; // TODO: lau: extract string
          trailing = Icon(
            Icons.arrow_downward,
            size: 16,
            color: colorScheme.textMuted,
          );
          break;
        case SortKey.distanceDesc:
          text = "Similarity"; // TODO: lau: extract string
          trailing = Icon(
            Icons.arrow_upward,
            size: 16,
            color: colorScheme.textMuted,
          );
          break;
        case SortKey.count:
          text = "Count"; // TODO: lau: extract string
          trailing = Icon(
            Icons.arrow_downward,
            size: 16,
            color: colorScheme.textMuted,
          );
          break;
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: textTheme.miniBold,
          ),
          const SizedBox(width: 8),
          trailing,
        ],
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
          _sortKey = SortKey.values[index];
        });
        _sortSimilarFiles();
      },
      itemBuilder: (context) {
        return List.generate(SortKey.values.length, (index) {
          return PopupMenuItem(
            value: index,
            child: sortOptionContent(SortKey.values[index]),
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
  final List<String> _loadingMessages = [
    "Analyzing your photos locally", // TODO: lau: extract string
    "Finding similar images", // TODO: lau: extract string
    "Processing visual patterns", // TODO: lau: extract string
    "Comparing image features", // TODO: lau: extract string
    "Almost done", // TODO: lau: extract string
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

    // Cycle through loading messages
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
                      color: colorScheme.primary500.withOpacity(
                        _pulseAnimation.value * 0.1,
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
                            colorScheme.primary500.withOpacity(0),
                            colorScheme.primary500.withOpacity(0.3),
                            colorScheme.primary500.withOpacity(0.6),
                            colorScheme.primary500,
                            colorScheme.primary500.withOpacity(0),
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
                  "Processing locally", // TODO: lau: extract string
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
                      color: colorScheme.primary500.withOpacity(
                        value < 0.5 ? value * 2 : 2 - value * 2,
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
