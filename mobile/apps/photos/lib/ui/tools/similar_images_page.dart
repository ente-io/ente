import "dart:async";

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
import "package:photos/ui/common/loading_widget.dart";
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
  const SimilarImagesPage({super.key});

  @override
  State<SimilarImagesPage> createState() => _SimilarImagesPageState();
}

class _SimilarImagesPageState extends State<SimilarImagesPage> {
  static const crossAxisCount = 3;
  static const crossAxisSpacing = 12.0;
  static const autoSelectDistanceThreshold = 0.01;

  final _logger = Logger("SimilarImagesPage");
  bool _isDisposed = false;

  SimilarImagesPageState _pageState = SimilarImagesPageState.setup;
  double _distanceThreshold = 0.04; // Default value
  List<SimilarFiles> _similarFilesList = [];
  SortKey _sortKey = SortKey.distanceAsc;
  bool _exactSearch = false;

  late SelectedFiles _selectedFiles;

  @override
  void initState() {
    super.initState();
    _selectedFiles = SelectedFiles();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _selectedFiles.dispose();
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
    switch (_pageState) {
      case SimilarImagesPageState.setup:
        return _getSetupView();
      case SimilarImagesPageState.loading:
        return _getLoadingView();
      case SimilarImagesPageState.results:
        return _getResultsView();
    }
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
                "Exact search", // TODO: lau: extract string
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EnteLoadingWidget(),
          SizedBox(height: 16),
          Text("Analyzing images..."), // TODO: lau: extract string
        ],
      ),
    );
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
              "No Similar Images Found", // TODO: lau: extract string
              style: textTheme.h3Bold,
            ),
            const SizedBox(height: 8),
            Text(
              "Try adjusting the similarity threshold", // TODO: lau: extract string
              style: textTheme.body,
            ),
            const SizedBox(height: 32),
            ButtonWidget(
              labelText: "Try Again", // TODO: lau: extract string
              buttonType: ButtonType.secondary,
              onTap: () async {
                if (_isDisposed) return;
                setState(() {
                  _pageState = SimilarImagesPageState.setup;
                });
              },
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _similarFilesList.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                // Header item
                if (flagService.internalUser) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          "(I) Found ${_similarFilesList.length} groups of similar images", // TODO: lau: extract string
                          style: textTheme.bodyBold,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "(I) Threshold: ${_distanceThreshold.toStringAsFixed(2)}", // TODO: lau: extract string
                          style: textTheme.miniMuted,
                        ),
                      ],
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }

              // Similar files groups (index - 1 because first item is header)
              final similarFiles = _similarFilesList[index - 1];
              return _buildSimilarFilesGroup(similarFiles);
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

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: hasSelectedFiles
              ? SafeArea(
                  child: Container(
                    key: const ValueKey('bottom_buttons'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: crossAxisSpacing,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: getEnteColorScheme(context).backgroundBase,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ButtonWidget(
                            labelText:
                                "Delete $selectedCount photos", // TODO: lau: extract string
                            buttonType: ButtonType.critical,
                            onTap: () async {
                              await _deleteFiles(
                                _selectedFiles.files,
                                showDialog: true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ButtonWidget(
                            labelText:
                                "Unselect all", // TODO: lau: extract string
                            buttonType: ButtonType.secondary,
                            onTap: () async {
                              _selectedFiles.clearAll(fireEvent: false);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
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

      final similarFiles = await SimilarImagesService.instance
          .getSimilarFiles(_distanceThreshold, exact: _exactSearch);
      _logger.info(
        "Found ${similarFiles.length} groups of similar images",
      );

      _similarFilesList = similarFiles;
      _pageState = SimilarImagesPageState.results;
      _sortSimilarFiles();
      _autoSelectSimilarFiles();

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
        _similarFilesList
            .sort((a, b) => a.furthestDistance.compareTo(b.furthestDistance));
        break;
      case SortKey.distanceDesc:
        _similarFilesList
            .sort((a, b) => b.furthestDistance.compareTo(a.furthestDistance));
        break;
      case SortKey.count:
        _similarFilesList
            .sort((a, b) => b.files.length.compareTo(a.files.length));
        break;
    }
    if (_isDisposed) return;
    setState(() {});
  }

  void _autoSelectSimilarFiles() {
    final filesToSelect = <EnteFile>{};
    int groupsProcessed = 0;
    int groupsAutoSelected = 0;

    for (final similarFilesGroup in _similarFilesList) {
      groupsProcessed++;
      if (similarFilesGroup.furthestDistance < autoSelectDistanceThreshold) {
        groupsAutoSelected++;
        // Skip the first file (keep it unselected) and select the rest
        for (int i = 1; i < similarFilesGroup.files.length; i++) {
          filesToSelect.add(similarFilesGroup.files[i]);
        }
      }
    }

    if (filesToSelect.isNotEmpty) {
      _selectedFiles.selectAll(filesToSelect);
      _logger.info(
        "Auto-selected ${filesToSelect.length} files from $groupsAutoSelected/$groupsProcessed groups (threshold: $autoSelectDistanceThreshold)",
      );
    } else {
      _logger.info(
        "No files auto-selected from $groupsProcessed groups (threshold: $autoSelectDistanceThreshold)",
      );
    }
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
                    (flagService.internalUser
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
                    final hasAnySelection = _selectedFiles.files.isNotEmpty;
                    final allGroupFilesSelected = similarFiles.files.every(
                      (file) => _selectedFiles.isFileSelected(file),
                    );

                    if (groupSelectedFiles.isNotEmpty) {
                      return _getSmallDeleteButton(
                        groupSelectedFiles,
                        allFilesFromGroupSelected,
                      );
                    } else if (hasAnySelection) {
                      return _getSmallSelectButton(allGroupFilesSelected, () {
                        if (allGroupFilesSelected) {
                          // Unselect all files in this group
                          _selectedFiles.unSelectAll(
                            similarFiles.files.toSet(),
                          );
                        } else {
                          // Select all files in this group
                          _selectedFiles.selectAll(
                            similarFiles.files.sublist(1).toSet(),
                          );
                        }
                      });
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return _buildFile(
                context,
                similarFiles.files[index],
                similarFiles.files,
                index,
              );
            },
            itemCount: similarFiles.files.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: 0.70,
            ),
            padding: const EdgeInsets.all(0),
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
        firstButtonLabel: S.of(context).delete,
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
      for (final collectionID in collectionToFilesToAddMap.keys) {
        await CollectionsService.instance.addSilentlyToCollection(
          collectionID,
          collectionToFilesToAddMap[collectionID]!,
        );
      }
    }

    _selectedFiles.unSelectAll(allDeleteFiles);
    setState(() {});
    await deleteFilesFromRemoteOnly(context, allDeleteFiles.toList());
  }

  Widget _getSmallSelectButton(bool unselectAll, void Function() onTap) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: unselectAll
              ? getEnteColorScheme(context).primary500
              : getEnteColorScheme(context).strokeFaint,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          unselectAll
              ? "Unselect all" // TODO: lau: extract string
              : "Select extra", // TODO: lau: extract string
          style: textTheme.smallMuted.copyWith(
            color: unselectAll ? Colors.white : colorScheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _getSortMenu() {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    Text sortOptionText(SortKey key) {
      String text = key.toString();
      switch (key) {
        case SortKey.size:
          text = "Size"; // TODO: lau: extract string
          break;
        case SortKey.distanceAsc:
          text = "Distance ascending"; // TODO: lau: extract string
          break;
        case SortKey.distanceDesc:
          text = "Distance descending"; // TODO: lau: extract string
          break;
        case SortKey.count:
          text = "Count"; // TODO: lau: extract string
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
          _sortKey = SortKey.values[index];
        });
        _sortSimilarFiles();
      },
      itemBuilder: (context) {
        return List.generate(SortKey.values.length, (index) {
          return PopupMenuItem(
            value: index,
            child: Text(
              sortOptionText(SortKey.values[index]).data!,
              style: textTheme.miniBold,
            ),
          );
        });
      },
    );
  }
}
