import "dart:developer";

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/user_details_changed_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/viewer/file/detail_page.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import 'package:photos/utils/delete_file_util.dart';
import "package:photos/utils/dialog_util.dart";
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/standalone/data.dart';

class DeduplicatePage extends StatefulWidget {
  final List<DuplicateFiles> duplicates;

  const DeduplicatePage(this.duplicates, {super.key});

  @override
  State<DeduplicatePage> createState() => _DeduplicatePageState();
}

class _DeduplicatePageState extends State<DeduplicatePage> {
  static const crossAxisCount = 4;
  static const crossAxisSpacing = 4.0;
  static const headerRowCount = 3;

  final Set<int> selectedGrids = <int>{};

  late List<DuplicateFiles> _duplicates;

  SortKey sortKey = SortKey.size;
  late ValueNotifier<String> _deleteProgress;

  @override
  void initState() {
    _duplicates = widget.duplicates;
    _deleteProgress = ValueNotifier("");
    _selectAllGrids();
    super.initState();
  }

  @override
  void dispose() {
    _deleteProgress.dispose();
    super.dispose();
  }

  void _selectAllGrids() {
    selectedGrids.clear();
    for (int idx = 0; idx < _duplicates.length; idx++) {
      selectedGrids.add(idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    _sortDuplicates();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(S.of(context).deduplicateFiles),
        actions: <Widget>[
          PopupMenuButton(
            constraints: const BoxConstraints(minWidth: 180),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            onSelected: (dynamic value) {
              setState(() {
                selectedGrids.clear();
              });
            },
            offset: const Offset(0, 50),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: true,
                height: 32,
                child: Row(
                  children: [
                    const Icon(
                      Icons.remove_circle_outline,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        S.of(context).deselectAll,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _getBody(),
    );
  }

  void _sortDuplicates() {
    _duplicates.sort((first, second) {
      switch (sortKey) {
        case SortKey.size:
          final aSize = first.files.length * first.size;
          final bSize = second.files.length * second.size;
          return bSize - aSize;
        case SortKey.count:
          return second.files.length - first.files.length;
      }
    });
  }

  Widget _getBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ListView.builder(
            itemBuilder: (context, index) {
              if (index == 0) {
                return const SizedBox.shrink();
              } else if (index == 1) {
                return const SizedBox.shrink();
              } else if (index == 2) {
                if (_duplicates.isNotEmpty) {
                  return _getSortMenu(context);
                } else {
                  return const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: EmptyState(),
                  );
                }
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _getGridView(
                  _duplicates[index - headerRowCount],
                  index - headerRowCount,
                ),
              );
            },
            itemCount: _duplicates.length + headerRowCount,
            shrinkWrap: true,
          ),
        ),
        selectedGrids.isEmpty
            ? const SizedBox.shrink()
            : Column(
                children: [
                  ValueListenableBuilder(
                    valueListenable: _deleteProgress,
                    builder: (BuildContext context, value, Widget? child) {
                      if (value.isEmpty) {
                        return const SizedBox.shrink();
                      } else {
                        return Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            value, // Show the value
                            style: getEnteTextTheme(context).bodyMuted,
                          ),
                        );
                      }
                    },
                  ),
                  _getDeleteButton(),
                  const SizedBox(height: crossAxisSpacing / 2),
                ],
              ),
      ],
    );
  }

  Widget _getSortMenu(BuildContext context) {
    Text sortOptionText(SortKey key) {
      String text = key.toString();
      switch (key) {
        case SortKey.count:
          text = S.of(context).count;
          break;
        case SortKey.size:
          text = S.of(context).totalSize;
          break;
      }
      return Text(
        text,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontSize: 14,
              color: Theme.of(context).iconTheme.color!.withValues(alpha: 0.7),
            ),
      );
    }

    return Row(
      // h4ck to align PopupMenuItems to end
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox.shrink(),
        PopupMenuButton(
          initialValue: sortKey.index,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                sortOptionText(sortKey),
                const Padding(padding: EdgeInsets.only(left: 4)),
                Icon(
                  Icons.sort,
                  color: Theme.of(context).colorScheme.iconColor,
                  size: 20,
                ),
              ],
            ),
          ),
          onSelected: (int index) {
            setState(() {
              final newKey = SortKey.values[index];
              if (newKey == sortKey) {
                return;
              } else {
                sortKey = newKey;
                if (selectedGrids.length != _duplicates.length) {
                  selectedGrids.clear();
                }
              }
            });
          },
          itemBuilder: (context) {
            return List.generate(SortKey.values.length, (index) {
              return PopupMenuItem(
                value: index,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: sortOptionText(SortKey.values[index]),
                ),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _getDeleteButton() {
    int fileCount = 0;
    int totalSize = 0;
    for (int index = 0; index < _duplicates.length; index++) {
      if (selectedGrids.contains(index)) {
        final int toDeleteCount = _duplicates[index].files.length - 1;
        fileCount += toDeleteCount;
        totalSize += toDeleteCount * _duplicates[index].size;
      }
    }
    final String text = S.of(context).deleteItemCount(fileCount);
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: crossAxisSpacing / 2),
          child: TextButton(
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.inverseBackgroundColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Padding(padding: EdgeInsets.all(4)),
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.inverseTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Padding(padding: EdgeInsets.all(2)),
                Text(
                  formatBytes(totalSize),
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .inverseTextColor
                        .withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const Padding(padding: EdgeInsets.all(2)),
              ],
            ),
            onPressed: () async {
              try {
                await deleteDuplicates(totalSize);
              } catch (e) {
                log("Failed to delete duplicates", error: e);
                showGenericErrorDialog(context: context, error: e).ignore();
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> deleteDuplicates(int totalSize) async {
    final List<EnteFile> filesToDelele = [];
    final Map<int, List<EnteFile>> collectionToFilesToAddMap = {};
    for (int index = 0; index < _duplicates.length; index++) {
      if (selectedGrids.contains(index)) {
        final sortedFiles = _duplicates[index].sortByLocalIDs();
        final EnteFile fileToKeep = sortedFiles.first;
        filesToDelele.addAll(sortedFiles.sublist(1));
        for (final collectionID in _duplicates[index].collectionIDs) {
          if (fileToKeep.collectionID == collectionID) {
            continue;
          }
          if (!collectionToFilesToAddMap.containsKey(collectionID)) {
            collectionToFilesToAddMap[collectionID] = [];
          }
          collectionToFilesToAddMap[collectionID]!.add(fileToKeep);
        }
      }
    }
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
        _deleteProgress.value = '$percentage%';
      }
      log("AddingNow ${collectionToFilesToAddMap[collectionID]!.length} files to $collectionID");
      await CollectionsService.instance.addSilentlyToCollection(
        collectionID,
        collectionToFilesToAddMap[collectionID]!,
      );
    }
    _deleteProgress.value = "";
    if (filesToDelele.isNotEmpty) {
      await deleteFilesFromRemoteOnly(context, filesToDelele);
      Bus.instance.fire(UserDetailsChangedEvent());
      Navigator.of(context)
          .pop(DeduplicationResult(filesToDelele.length, totalSize));
    }
  }

  Widget _getGridView(DuplicateFiles duplicates, int itemIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
          child: GestureDetector(
            onTap: () {
              if (selectedGrids.contains(itemIndex)) {
                selectedGrids.remove(itemIndex);
              } else {
                selectedGrids.add(itemIndex);
              }
              setState(() {});
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).duplicateItemsGroup(
                        duplicates.files.length,
                        formatBytes(duplicates.size),
                      ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                !selectedGrids.contains(itemIndex)
                    ? Icon(
                        Icons.check_circle_outlined,
                        color: getEnteColorScheme(context).strokeMuted,
                        size: 24,
                      )
                    : const Icon(
                        Icons.check_circle,
                        size: 24,
                      ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: crossAxisSpacing / 2),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // to disable GridView's scrolling
            itemBuilder: (context, index) {
              return _buildFile(context, duplicates.files[index], itemIndex);
            },
            itemCount: duplicates.files.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: 0.75,
            ),
            padding: const EdgeInsets.all(0),
          ),
        ),
      ],
    );
  }

  Widget _buildFile(BuildContext context, EnteFile file, int index) {
    return GestureDetector(
      onTap: () {
        final files = _duplicates[index].files;
        routeToPage(
          context,
          DetailPage(
            DetailPageConfiguration(
              files,
              files.indexOf(file),
              "deduplicate_",
              mode: DetailPageMode.minimalistic,
            ),
          ),
          forceCustomPageRoute: true,
        );
      },
      onLongPress: () {
        HapticFeedback.lightImpact();
        final files = _duplicates[index].files;
        routeToPage(
          context,
          DetailPage(
            DetailPageConfiguration(
              files,
              files.indexOf(file),
              "deduplicate_",
              mode: DetailPageMode.minimalistic,
            ),
          ),
          forceCustomPageRoute: true,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            //the numerator will give the width of the screen excuding the whitespaces in the the grid row
            height: (MediaQuery.of(context).size.width -
                    (crossAxisSpacing * crossAxisCount)) /
                crossAxisCount,
            child: Hero(
              tag: "deduplicate_" + file.tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ThumbnailWidget(
                  file,
                  diskLoadDeferDuration: galleryThumbnailDiskLoadDeferDuration,
                  serverLoadDeferDuration:
                      galleryThumbnailServerLoadDeferDuration,
                  shouldShowLivePhotoOverlay: true,
                  key: Key("deduplicate_" + file.tag),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(
              CollectionsService.instance
                  .getCollectionByID(file.collectionID!)!
                  .displayName,
              style:
                  Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

enum SortKey { size, count }

class DeduplicationResult {
  final int count;
  final int size;

  DeduplicationResult(this.count, this.size);
}
