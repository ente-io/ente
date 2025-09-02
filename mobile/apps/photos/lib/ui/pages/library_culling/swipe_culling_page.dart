import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/similar_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/pages/library_culling/models/swipe_culling_state.dart';
import 'package:photos/ui/pages/library_culling/widgets/group_carousel.dart';
import 'package:photos/ui/pages/library_culling/widgets/group_summary_popup.dart';
import 'package:photos/ui/pages/library_culling/widgets/swipeable_photo_card.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/standalone/data.dart';

class SwipeCullingPage extends StatefulWidget {
  final List<SimilarFiles> similarFiles;

  const SwipeCullingPage({
    super.key,
    required this.similarFiles,
  });

  @override
  State<SwipeCullingPage> createState() => _SwipeCullingPageState();
}

class _SwipeCullingPageState extends State<SwipeCullingPage>
    with TickerProviderStateMixin {
  final _logger = Logger("SwipeCullingPage");

  late List<SimilarFiles> groups;
  int currentGroupIndex = 0;
  int currentImageIndex = 0;
  Map<EnteFile, SwipeDecision> decisions = {};
  Map<int, List<SwipeAction>> groupHistories = {};
  List<SwipeAction> fullHistory = [];

  final CardSwiperController controller = CardSwiperController();
  late ValueNotifier<String> _deleteProgress;

  // Animation controllers for celebrations
  late AnimationController _celebrationController;
  late AnimationController _progressRingController;
  bool _showingCelebration = false;

  @override
  void initState() {
    super.initState();
    _deleteProgress = ValueNotifier("");
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressRingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _initializeGroups();
  }

  @override
  void dispose() {
    _deleteProgress.dispose();
    _celebrationController.dispose();
    _progressRingController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _initializeGroups() {
    // Filter groups (no singles, no 50+)
    groups = widget.similarFiles
        .where((g) => g.files.length > 1 && g.files.length < 50)
        .toList();

    // Initialize all as undecided
    for (final group in groups) {
      for (final file in group.files) {
        decisions[file] = SwipeDecision.undecided;
      }
      groupHistories[groups.indexOf(group)] = [];
    }
  }

  List<EnteFile> get currentGroupFiles {
    if (groups.isEmpty || currentGroupIndex >= groups.length) {
      return [];
    }
    return groups[currentGroupIndex].files;
  }

  EnteFile? get currentFile {
    final files = currentGroupFiles;
    if (files.isEmpty || currentImageIndex >= files.length) {
      return null;
    }
    return files[currentImageIndex];
  }

  int get totalDeletionCount {
    return decisions.values.where((d) => d == SwipeDecision.delete).length;
  }

  GroupProgress getGroupProgress(int groupIndex) {
    if (groupIndex >= groups.length) {
      return GroupProgress(totalImages: 0, reviewedImages: 0, deletionCount: 0);
    }

    final group = groups[groupIndex];
    int reviewed = 0;
    int toDelete = 0;

    for (final file in group.files) {
      final decision = decisions[file] ?? SwipeDecision.undecided;
      if (decision != SwipeDecision.undecided) {
        reviewed++;
        if (decision == SwipeDecision.delete) {
          toDelete++;
        }
      }
    }

    return GroupProgress(
      totalImages: group.files.length,
      reviewedImages: reviewed,
      deletionCount: toDelete,
    );
  }

  void _handleSwipeDecision(SwipeDecision decision) {
    final file = currentFile;
    if (file == null) return;

    // Haptic feedback for swipe action
    HapticFeedback.lightImpact();

    setState(() {
      decisions[file] = decision;

      final action = SwipeAction(
        file: file,
        decision: decision,
        timestamp: DateTime.now(),
        groupIndex: currentGroupIndex,
      );

      groupHistories[currentGroupIndex]?.add(action);
      fullHistory.add(action);

      // Move to next image
      if (currentImageIndex < currentGroupFiles.length - 1) {
        currentImageIndex++;
      } else {
        // Group complete - check if all images marked for deletion
        final groupProgress = getGroupProgress(currentGroupIndex);
        if (groupProgress.deletionCount == groupProgress.totalImages &&
            groupProgress.totalImages > 0) {
          _showAllInGroupDeletionDialog();
        } else {
          _handleGroupCompletion();
        }
      }
    });
  }

  void _handleGroupCompletion() async {
    if (_showingCelebration) return;

    // Haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _showingCelebration = true;
    });

    // Start progress ring animation
    _progressRingController.forward();

    // Wait for progress ring to complete or user to skip
    await Future.delayed(const Duration(seconds: 2));

    // Quick celebration based on group size
    final groupSize = currentGroupFiles.length;
    if (groupSize <= 5) {
      _celebrationController.duration = const Duration(milliseconds: 500);
    } else if (groupSize <= 15) {
      _celebrationController.duration = const Duration(milliseconds: 700);
    } else {
      _celebrationController.duration = const Duration(milliseconds: 800);
    }

    _celebrationController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // Move to next group or show completion
    if (currentGroupIndex < groups.length - 1) {
      setState(() {
        currentGroupIndex++;
        currentImageIndex = 0;
        _showingCelebration = false;
      });
      _celebrationController.reset();
      _progressRingController.reset();
    } else {
      _showCompletionDialog();
    }
  }

  void _showAllInGroupDeletionDialog() {
    final groupSize = currentGroupFiles.length;

    showDialog(
      context: context,
      builder: (context) {
        final theme = getEnteColorScheme(context);
        return AlertDialog(
          title: Text(AppLocalizations.of(context).deleteAllInGroup),
          content: Text(
            AppLocalizations.of(context).allImagesMarkedForDeletion(count: groupSize),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Review again - reset this group's decisions
                setState(() {
                  for (final file in currentGroupFiles) {
                    decisions[file] = SwipeDecision.undecided;
                  }
                  currentImageIndex = 0;
                  groupHistories[currentGroupIndex]?.clear();
                });
              },
              child: Text(AppLocalizations.of(context).reviewAgain),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleGroupCompletion();
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.warning700,
              ),
              child: Text(AppLocalizations.of(context).delete),
            ),
          ],
        );
      },
    );
  }

  void _showCompletionDialog() {
    final filesToDelete = <EnteFile>{};
    int totalSize = 0;

    for (final entry in decisions.entries) {
      if (entry.value == SwipeDecision.delete) {
        filesToDelete.add(entry.key);
        totalSize += entry.key.fileSize ?? 0;
      }
    }

    if (filesToDelete.isEmpty) {
      Navigator.of(context).pop(0);
      return;
    }

    showChoiceDialog(
      context,
      title: AppLocalizations.of(context).deletePhotos,
      body: AppLocalizations.of(context).deletePhotosBody(
            count: filesToDelete.length.toString(),
            size: formatBytes(totalSize),
          ),
      firstButtonLabel: AppLocalizations.of(context).delete,
      isCritical: true,
      firstButtonOnTap: () async {
        try {
          await _deleteFilesLogic(filesToDelete, true);
          if (mounted) {
            Navigator.of(context).pop(filesToDelete.length);
          }
        } catch (e, s) {
          _logger.severe("Failed to delete files", e, s);
          if (mounted) {
            await showGenericErrorDialog(context: context, error: e);
          }
        }
      },
    );
  }

  void _handleUndo() {
    if (groupHistories[currentGroupIndex]?.isEmpty ?? true) return;

    setState(() {
      final lastAction = groupHistories[currentGroupIndex]!.removeLast();
      fullHistory.removeLast();
      decisions[lastAction.file] = SwipeDecision.undecided;

      // Move back to the undone image
      final fileIndex = currentGroupFiles.indexOf(lastAction.file);
      if (fileIndex != -1) {
        currentImageIndex = fileIndex;
      }
    });
  }

  Map<int, GroupProgress> get progressMap {
    final map = <int, GroupProgress>{};
    for (int i = 0; i < groups.length; i++) {
      map[i] = getGroupProgress(i);
    }
    return map;
  }

  void _switchToGroup(int groupIndex) {
    if (groupIndex < 0 || groupIndex >= groups.length) return;

    setState(() {
      currentGroupIndex = groupIndex;
      currentImageIndex = 0;

      // Find first undecided image in the group
      final files = groups[groupIndex].files;
      for (int i = 0; i < files.length; i++) {
        if (decisions[files[i]] == SwipeDecision.undecided) {
          currentImageIndex = i;
          break;
        }
      }
    });
  }

  void _showGroupSummaryPopup(int groupIndex) {
    if (groupIndex < 0 || groupIndex >= groups.length) return;

    final group = groups[groupIndex];

    showDialog(
      context: context,
      builder: (context) => GroupSummaryPopup(
        group: group,
        decisions: decisions,
        onUndoAll: () {
          setState(() {
            // Reset all decisions for this group
            for (final file in group.files) {
              decisions[file] = SwipeDecision.undecided;
            }
            // Clear group history
            groupHistories[groupIndex]?.clear();
            // Remove from full history
            fullHistory
                .removeWhere((action) => action.groupIndex == groupIndex);
          });
          Navigator.of(context).pop();
          _switchToGroup(groupIndex);
        },
        onDeleteThese: () async {
          // Get files to delete from this group
          final filesToDelete = <EnteFile>{};
          for (final file in group.files) {
            if (decisions[file] == SwipeDecision.delete) {
              filesToDelete.add(file);
            }
          }

          if (filesToDelete.isNotEmpty) {
            Navigator.of(context).pop();
            await _deleteFilesLogic(filesToDelete, true);

            // Remove this group from the list if all deleted
            if (filesToDelete.length == group.files.length) {
              setState(() {
                groups.removeAt(groupIndex);
                if (currentGroupIndex >= groups.length && groups.isNotEmpty) {
                  currentGroupIndex = groups.length - 1;
                  currentImageIndex = 0;
                }
              });
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteFilesLogic(
    Set<EnteFile> filesToDelete,
    bool createSymlink,
  ) async {
    if (filesToDelete.isEmpty) {
      return;
    }

    final Map<int, Set<EnteFile>> collectionToFilesToAddMap = {};
    final allDeleteFiles = <EnteFile>{};

    for (final group in groups) {
      final groupDeleteFiles = <EnteFile>{};
      for (final file in filesToDelete) {
        if (group.containsFile(file)) {
          groupDeleteFiles.add(file);
          allDeleteFiles.add(file);
        }
      }

      if (groupDeleteFiles.isNotEmpty && createSymlink) {
        final filesToKeep =
            group.files.where((f) => !groupDeleteFiles.contains(f)).toSet();
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

    final int collectionCnt = collectionToFilesToAddMap.keys.length;
    if (createSymlink) {
      final userID = Configuration.instance.getUserID();
      int progress = 0;
      for (final collectionID in collectionToFilesToAddMap.keys) {
        if (!mounted) {
          return;
        }
        if (collectionCnt > 2) {
          progress++;
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
            "Skipping adding symlinks to collection $collectionID due to missing permissions",
          );
        }
      }
    }

    if (collectionCnt > 2) {
      _deleteProgress.value = "";
    }

    await deleteFilesFromRemoteOnly(context, allDeleteFiles.toList());

    // Show congratulations if more than 100 files deleted
    if (allDeleteFiles.length > 100 && mounted) {
      final int totalSize = allDeleteFiles.fold<int>(
        0,
        (sum, file) => sum + (file.fileSize ?? 0),
      );
      _showCongratulationsDialog(allDeleteFiles.length, totalSize);
    }
  }

  void _showCongratulationsDialog(int deletedCount, int totalSize) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).congratulations),
          content: Text(
            AppLocalizations.of(context).deletedPhotosWithSize(
                  count: deletedCount.toString(),
                  size: formatBytes(totalSize),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).ok),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = getEnteColorScheme(context);

    if (groups.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).review),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context).noImagesSelected),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (totalDeletionCount > 0) {
                  // TODO: Show exit confirmation if there are pending deletions
                }
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              "${currentImageIndex + 1} of ${currentGroupFiles.length}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            actions: [
              if (totalDeletionCount > 0)
                TextButton(
                  onPressed: _showCompletionDialog,
                  child: Text(
                    "Delete ($totalDeletionCount)",
                    style: TextStyle(color: theme.warning700),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Group carousel at top
              if (groups.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: GroupCarousel(
                    groups: groups,
                    currentGroupIndex: currentGroupIndex,
                    onGroupSelected: _switchToGroup,
                    onGroupLongPress: _showGroupSummaryPopup,
                    progressMap: progressMap,
                  ),
                ),
              Expanded(
                child: currentFile != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          CardSwiper(
                            controller: controller,
                            cardsCount:
                                currentGroupFiles.length - currentImageIndex,
                            numberOfCardsDisplayed: 1,
                            backCardOffset: const Offset(0, 0),
                            padding: const EdgeInsets.all(24.0),
                            cardBuilder: (
                                context,
                                index,
                                percentThresholdX,
                                percentThresholdY,
                            ) {
                              final fileIndex = currentImageIndex + index;
                              if (fileIndex >= currentGroupFiles.length) {
                                return const SizedBox.shrink();
                              }

                              final file = currentGroupFiles[fileIndex];
                              final isFirst = fileIndex == 0;

                              // Calculate swipe progress for overlay effects
                              final swipeProgress = percentThresholdX / 100;
                              final isSwipingLeft = swipeProgress < -0.1;
                              final isSwipingRight = swipeProgress > 0.1;

                              return SwipeablePhotoCard(
                                file: file,
                                showBestPictureBadge: isFirst,
                                swipeProgress: swipeProgress,
                                isSwipingLeft: isSwipingLeft,
                                isSwipingRight: isSwipingRight,
                              );
                            },
                            onSwipe: (previousIndex, currentIndex, direction) {
                              final decision =
                                  direction == CardSwiperDirection.left
                                      ? SwipeDecision.delete
                                      : SwipeDecision.keep;

                              // Handle the swipe decision
                              _handleSwipeDecision(decision);

                              return true;
                            },
                            onEnd: () {
                              // All cards in current group have been swiped
                              // This is handled in _handleSwipeDecision when reaching last card
                            },
                            isDisabled: false,
                            threshold: 50,
                          ),

                          // Celebration overlay
                          if (_showingCelebration)
                            AnimatedBuilder(
                              animation: _progressRingController,
                              builder: (context, child) {
                                return Container(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Progress ring
                                            SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: CircularProgressIndicator(
                                                value: _progressRingController
                                                    .value,
                                                strokeWidth: 4,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                  theme.primary500,
                                                ),
                                              ),
                                            ),
                                            // Checkmark or celebration icon
                                            Icon(
                                              Icons.check_circle_outline,
                                              size: 60,
                                              color: theme.primary500,
                                            )
                                                .animate(
                                                    controller:
                                                        _celebrationController,
                                                )
                                                .scaleXY(
                                                  begin: 0.8,
                                                  end: 1.2,
                                                  curve: Curves.elasticOut,
                                                )
                                                .fadeIn(),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppLocalizations.of(context).groupComplete,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                              ),
                                        )
                                            .animate(
                                                controller:
                                                    _celebrationController,
                                            )
                                            .fadeIn(delay: 200.ms),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      )
                    : Center(
                        child: Text(AppLocalizations.of(context).noImagesSelected),
                      ),
              ),
              // Action buttons at bottom
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: currentFile != null
                          ? () => controller.swipe(CardSwiperDirection.left)
                          : null,
                      icon: Icon(Icons.delete_outline, color: theme.warning700),
                      iconSize: 32,
                    ),
                    IconButton(
                      onPressed: _handleUndo,
                      icon: const Icon(Icons.undo),
                      iconSize: 32,
                    ),
                    IconButton(
                      onPressed: currentFile != null
                          ? () => controller.swipe(CardSwiperDirection.right)
                          : null,
                      icon: Icon(
                          Icons.thumb_up_outlined,
                          color: theme.primary700,
                      ),
                      iconSize: 32,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Progress overlay during deletion
        ValueListenableBuilder(
          valueListenable: _deleteProgress,
          builder: (context, value, child) {
            if (value.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              color: theme.backgroundBase.withValues(alpha: 0.8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.backgroundElevated,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: theme.strokeFaint,
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
                          valueColor: AlwaysStoppedAnimation(theme.primary500),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Deleting... $value',
                        style: Theme.of(context).textTheme.bodyMedium,
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
}
