import 'dart:async' show Future, unawaited;
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

  late CardSwiperController controller;
  late ValueNotifier<String> _deleteProgress;

  // Animation controllers for celebrations
  late AnimationController _celebrationController;
  late AnimationController _progressRingController;
  bool _showingCelebration = false;

  @override
  void initState() {
    super.initState();
    controller = CardSwiperController();
    _deleteProgress = ValueNotifier("");
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    unawaited(HapticFeedback.lightImpact());

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
    unawaited(HapticFeedback.mediumImpact());

    setState(() {
      _showingCelebration = true;
    });

    // Ultra-quick celebration animation
    _celebrationController.duration = const Duration(milliseconds: 250);
    unawaited(_celebrationController.forward());
    await Future.delayed(const Duration(milliseconds: 250));

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

    showChoiceDialog(
      context,
      title: AppLocalizations.of(context).deleteAllInGroup,
      body: AppLocalizations.of(context)
          .allImagesMarkedForDeletion(count: groupSize),
      firstButtonLabel: AppLocalizations.of(context).confirm,
      secondButtonLabel: AppLocalizations.of(context).reviewAgain,
      isCritical: true,
      firstButtonOnTap: () async {
        _handleGroupCompletion();
      },
      secondButtonOnTap: () async {
        // Review again - reset this group's decisions
        setState(() {
          for (final file in currentGroupFiles) {
            decisions[file] = SwipeDecision.undecided;
          }
          currentImageIndex = 0;
          groupHistories[currentGroupIndex]?.clear();
        });
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

      // Reset the controller to ensure clean state
      controller.dispose();
      controller = CardSwiperController();
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

  Widget _buildProgressDots(theme) {
    final totalImages = currentGroupFiles.length;

    if (totalImages == 0) return const SizedBox.shrink();

    // Limit dots to max 10 for readability
    const maxDots = 10;
    final showAllDots = totalImages <= maxDots;

    return SizedBox(
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          showAllDots ? totalImages : maxDots,
          (index) {
            // For collapsed view, calculate which image this dot represents
            final imageIndex =
                showAllDots ? index : (index * totalImages / maxDots).floor();

            final decision = decisions[currentGroupFiles[imageIndex]];
            final isCurrent = showAllDots
                ? index == currentImageIndex
                : imageIndex <= currentImageIndex &&
                    (index == maxDots - 1 ||
                        ((index + 1) * totalImages / maxDots).floor() >
                            currentImageIndex);

            Color dotColor;
            double dotSize = 6;

            if (decision == SwipeDecision.delete) {
              dotColor = theme.warning700;
            } else if (decision == SwipeDecision.keep) {
              dotColor = theme.primary500;
            } else if (isCurrent) {
              dotColor = theme.textBase;
              dotSize = 8;
            } else {
              dotColor = theme.strokeFaint;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            );
          },
        ),
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
            title: const Text(''), // Empty title
            actions: [
              if (totalDeletionCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: _showCompletionDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8,),
                      decoration: BoxDecoration(
                        color: theme.warning500.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 12,
                            color: theme.warning500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)
                                .deleteWithCount(count: totalDeletionCount),
                            style: getEnteTextTheme(context).smallBold.copyWith(
                                  color: theme.warning500,
                                ),
                          ),
                        ],
                      ),
                    ),
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
              // Progress dots above image
              if (currentFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _buildProgressDots(theme),
                ),
              Expanded(
                child: currentFile != null
                    ? Column(
                        children: [
                          Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Use a unique key for each group to force rebuild
                                CardSwiper(
                                  key: ValueKey(
                                      'swiper_${currentGroupIndex}_$currentImageIndex',),
                                  controller: controller,
                                  cardsCount: currentGroupFiles.length -
                                      currentImageIndex,
                                  numberOfCardsDisplayed:
                                      (currentGroupFiles.length -
                                                  currentImageIndex) >=
                                              2
                                          ? 2
                                          : 1, // Show 2 cards only if available
                                  backCardOffset: const Offset(
                                      0, -50,), // Very subtle peek from top
                                  padding: const EdgeInsets.all(20.0),
                                  cardBuilder: (
                                    context,
                                    index,
                                    percentThresholdX,
                                    percentThresholdY,
                                  ) {
                                    final fileIndex = currentImageIndex + index;
                                    if (fileIndex >= currentGroupFiles.length) {
                                      // Return a placeholder container instead of SizedBox.shrink()
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: theme.backgroundBase,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      );
                                    }

                                    final file = currentGroupFiles[fileIndex];
                                    final isBackCard = index >
                                        0; // Check if this is the back card

                                    // Calculate swipe progress for overlay effects
                                    final swipeProgress =
                                        percentThresholdX / 100;
                                    final isSwipingLeft = swipeProgress < -0.1;
                                    final isSwipingRight = swipeProgress > 0.1;

                                    // Wrap back card with darkening/opacity effect
                                    Widget card = SwipeablePhotoCard(
                                      key: ValueKey(
                                          file.uploadedFileID ?? file.localID,),
                                      file: file,
                                      swipeProgress:
                                          isBackCard ? 0 : swipeProgress,
                                      isSwipingLeft:
                                          isBackCard ? false : isSwipingLeft,
                                      isSwipingRight:
                                          isBackCard ? false : isSwipingRight,
                                      showFileInfo:
                                          !isBackCard, // Hide file info for back card
                                    );

                                    // Apply darkening to the back card (no clipping, show full image)
                                    if (isBackCard) {
                                      card = ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withValues(
                                              alpha: 0.4,), // Darken the preview
                                          BlendMode.darken,
                                        ),
                                        child: Opacity(
                                          opacity:
                                              0.6, // Make it more transparent
                                          child: card,
                                        ),
                                      );
                                    }

                                    return card;
                                  },
                                  onSwipe:
                                      (previousIndex, currentIndex, direction) {
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

                                // Minimal celebration overlay
                                if (_showingCelebration)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    child: Center(
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 48,
                                        color: theme.primary500,
                                      )
                                          .animate(
                                            controller: _celebrationController,
                                          )
                                          .scaleXY(
                                            begin: 0.5,
                                            end: 1.2,
                                            curve: Curves.easeOut,
                                          )
                                          .fadeIn(
                                            duration: 100.ms,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child:
                            Text(AppLocalizations.of(context).noImagesSelected),
                      ),
              ),
              // Action buttons at bottom
              Padding(
                padding: const EdgeInsets.only(
                  left: 32,
                  right: 32,
                  bottom: 48,
                  top: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Delete button - 72x72
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: currentFile != null
                            ? theme.backgroundElevated2
                            : theme.backgroundBase,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: currentFile != null
                              ? theme.strokeFaint
                              : theme.strokeFainter,
                          width: 1,
                        ),
                        boxShadow: currentFile != null
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: currentFile != null
                              ? () {
                                  HapticFeedback.lightImpact();
                                  controller.swipe(CardSwiperDirection.left);
                                }
                              : null,
                          child: Center(
                            child: Icon(
                              Icons.close,
                              color: currentFile != null
                                  ? theme.warning700
                                  : theme.strokeFainter,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Undo button without container
                    IconButton(
                      onPressed: _handleUndo,
                      icon: Icon(
                        Icons.replay,
                        color: theme.textMuted.withValues(alpha: 0.6),
                        size: 28,
                      ),
                      padding: const EdgeInsets.all(12),
                      splashRadius: 28,
                    ),
                    // Keep button - 72x72
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: currentFile != null
                            ? theme.backgroundElevated2
                            : theme.backgroundBase,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: currentFile != null
                              ? theme.strokeFaint
                              : theme.strokeFainter,
                          width: 1,
                        ),
                        boxShadow: currentFile != null
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: currentFile != null
                              ? () {
                                  HapticFeedback.lightImpact();
                                  controller.swipe(CardSwiperDirection.right);
                                }
                              : null,
                          child: Center(
                            child: Icon(
                              Icons.thumb_up_outlined,
                              color: currentFile != null
                                  ? theme.primary700
                                  : theme.strokeFainter,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
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
