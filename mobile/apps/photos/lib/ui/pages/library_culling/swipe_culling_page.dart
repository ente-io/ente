import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/similar_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/pages/library_culling/models/swipe_culling_state.dart';
import 'package:photos/ui/pages/library_culling/widgets/swipeable_photo_card.dart';
import 'package:photos/ui/pages/library_culling/widgets/group_carousel.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/standalone/data.dart';

class SwipeCullingPage extends StatefulWidget {
  final List<SimilarFiles> similarFiles;

  const SwipeCullingPage({
    Key? key,
    required this.similarFiles,
  }) : super(key: key);

  @override
  State<SwipeCullingPage> createState() => _SwipeCullingPageState();
}

class _SwipeCullingPageState extends State<SwipeCullingPage> {
  final _logger = Logger("SwipeCullingPage");
  
  late List<SimilarFiles> groups;
  int currentGroupIndex = 0;
  int currentImageIndex = 0;
  Map<EnteFile, SwipeDecision> decisions = {};
  Map<int, List<SwipeAction>> groupHistories = {};
  List<SwipeAction> fullHistory = [];
  
  final CardSwiperController controller = CardSwiperController();
  late ValueNotifier<String> _deleteProgress;

  @override
  void initState() {
    super.initState();
    _deleteProgress = ValueNotifier("");
    _initializeGroups();
  }
  
  @override
  void dispose() {
    _deleteProgress.dispose();
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

  void _handleGroupCompletion() {
    // TODO: Show minimal celebration animation
    // For now, just move to next group
    if (currentGroupIndex < groups.length - 1) {
      setState(() {
        currentGroupIndex++;
        currentImageIndex = 0;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showAllInGroupDeletionDialog() {
    // TODO: Implement confirmation dialog for all-in-group deletion
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
      title: S.of(context).deletePhotos,
      body: S.of(context).deletePhotosBody(
        filesToDelete.length.toString(),
        formatBytes(totalSize),
      ),
      firstButtonLabel: S.of(context).delete,
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
    // TODO: Implement group summary popup
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
        final filesToKeep = group.files.where((f) => !groupDeleteFiles.contains(f)).toSet();
        final collectionIDs = filesToKeep.map((file) => file.collectionID).toSet();
        
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
        final collection = CollectionsService.instance.getCollectionByID(collectionID);
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
        final theme = getEnteColorScheme(context);
        return AlertDialog(
          title: Text(S.of(context).congratulations),
          content: Text(
            S.of(context).deletedPhotosWithSize(
              deletedCount.toString(),
              formatBytes(totalSize),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).ok),
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
          title: Text(S.of(context).review),
        ),
        body: Center(
          child: Text(S.of(context).noImagesSelected),
        ),
      );
    }

    return Scaffold(
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
                ? CardSwiper(
                    controller: controller,
                    cardsCount: currentGroupFiles.length - currentImageIndex,
                    numberOfCardsDisplayed: 1,
                    backCardOffset: const Offset(0, 0),
                    padding: const EdgeInsets.all(24.0),
                    cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
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
                      final decision = direction == CardSwiperDirection.left
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
                  )
                : Center(
                    child: Text(S.of(context).noImagesSelected),
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
                  icon: Icon(Icons.thumb_up_outlined, color: theme.primary700),
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}