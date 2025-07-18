import "dart:core";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/gallery/fixed_extent_grid_row.dart";
import "package:photos/models/gallery/fixed_extent_section_layout.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/viewer/gallery/component/gallery_file_widget.dart";
import "package:photos/ui/viewer/gallery/component/group/group_header_widget.dart";
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:photos/ui/viewer/gallery/scrollbar/custom_scroll_bar.dart";
import "package:uuid/uuid.dart";

/// In order to make the gallery performant when GroupTypes do not show group
/// headers, groups are still created here but with the group header replaced by
/// the grid's main axis spacing.
class GalleryGroups {
  final List<EnteFile> allFiles;
  final GroupType groupType;
  final SelectedFiles? selectedFiles;
  final bool limitSelectionToOne;
  final String tagPrefix;
  final bool showSelectAll;
  final _logger = Logger("GalleryGroups");

  //TODO: Add support for sort order
  final bool sortOrderAsc;
  final double widthAvailable;
  final double groupHeaderExtent;
  GalleryGroups({
    required this.allFiles,
    required this.groupType,
    required this.widthAvailable,
    required this.selectedFiles,
    required this.tagPrefix,
    this.sortOrderAsc = true,

    /// Should be GroupGallery.spacing if GroupType.showGroupHeader() is false.
    required this.groupHeaderExtent,
    required this.showSelectAll,
    this.limitSelectionToOne = false,
  }) {
    init();
    if (!groupType.showGroupHeader()) {
      assert(
        groupHeaderExtent == spacing,
        '''groupHeaderExtent should be equal to spacing when group header is not 
        shown since the header is just replaced by the grid's main axis spacing''',
      );
    }
  }

  static const double spacing = 2.0;

  late final int crossAxisCount;
  late final List<FixedExtentSectionLayout> _groupLayouts;

  final List<String> _groupIds = [];
  final Map<String, List<EnteFile>> _groupIdToFilesMap = {};
  final Map<String, GroupHeaderData> _groupIdToHeaderDataMap = {};
  final Map<double, String> _scrollOffsetToGroupIdMap = {};
  final Map<String, double> _groupIdToScrollOffsetMap = {};
  final List<double> _groupScrollOffsets = [];
  final List<ScrollbarDivision> _scrollbarDivisions = [];
  final currentUserID = Configuration.instance.getUserID();
  final _uuid = const Uuid();

  List<String> get groupIDs => _groupIds;
  Map<String, List<EnteFile>> get groupIDToFilesMap => _groupIdToFilesMap;
  Map<String, GroupHeaderData> get groupIdToheaderDataMap =>
      _groupIdToHeaderDataMap;
  Map<double, String> get scrollOffsetToGroupIdMap => _scrollOffsetToGroupIdMap;
  Map<String, double> get groupIdToScrollOffsetMap => _groupIdToScrollOffsetMap;
  List<FixedExtentSectionLayout> get groupLayouts => _groupLayouts;
  List<double> get groupScrollOffsets => _groupScrollOffsets;
  List<ScrollbarDivision> get scrollbarDivisions => _scrollbarDivisions;

  void init() {
    crossAxisCount = localSettings.getPhotoGridSize();
    _buildGroups();
    _groupLayouts = _computeGroupLayouts();
    assert(groupIDs.length == _groupIdToFilesMap.length);
    assert(groupIDs.length == _groupIdToHeaderDataMap.length);
    assert(
      groupIDs.length == _scrollOffsetToGroupIdMap.length,
    );
    assert(
      groupIDs.length == _groupIdToScrollOffsetMap.length,
    );
    assert(groupIDs.length == _groupScrollOffsets.length);
  }

  List<FixedExtentSectionLayout> _computeGroupLayouts() {
    final stopwatch = Stopwatch()..start();
    final showGroupHeader = groupType.showGroupHeader();
    int currentIndex = 0;
    double currentOffset = 0.0;
    final tileHeight =
        (widthAvailable - (crossAxisCount - 1) * spacing) / crossAxisCount;
    final groupLayouts = <FixedExtentSectionLayout>[];

    final groupIDs = _groupIdToFilesMap.keys;

    for (final groupID in groupIDs) {
      final filesInGroup = _groupIdToFilesMap[groupID]!;
      final numberOfGridRows = (filesInGroup.length / crossAxisCount).ceil();
      final firstIndex = currentIndex == 0 ? currentIndex : currentIndex + 1;
      final lastIndex = firstIndex + numberOfGridRows;
      final minOffset = currentOffset;
      final maxOffset = minOffset +
          (numberOfGridRows * tileHeight) +
          (numberOfGridRows - 1) * spacing +
          groupHeaderExtent;
      final bodyFirstIndex = firstIndex + 1;

      groupLayouts.add(
        FixedExtentSectionLayout(
          firstIndex: firstIndex,
          lastIndex: lastIndex,
          minOffset: minOffset,
          maxOffset: maxOffset,
          headerExtent: groupHeaderExtent,
          tileHeight: tileHeight,
          spacing: spacing,
          builder: (context, rowIndex) {
            if (rowIndex == firstIndex) {
              if (showGroupHeader) {
                return GroupHeaderWidget(
                  title: _groupIdToHeaderDataMap[groupID]!
                      .groupType
                      .getTitle(context, groupIDToFilesMap[groupID]!.first),
                  gridSize: crossAxisCount,
                  filesInGroup: groupIDToFilesMap[groupID]!,
                  selectedFiles: selectedFiles,
                  showSelectAll: showSelectAll && !limitSelectionToOne,
                );
              } else {
                return const SizedBox(height: spacing);
              }
            } else {
              final gridRowChildren = <Widget>[];
              final firstIndexOfRowWrtFilesInGroup =
                  (rowIndex - bodyFirstIndex) * crossAxisCount;

              if (rowIndex == lastIndex) {
                final lastFile = filesInGroup.last;
                bool endOfListReached = false;
                int i = 0;
                while (!endOfListReached) {
                  gridRowChildren.add(
                    GalleryFileWidget(
                      key: ValueKey(
                        tagPrefix +
                            filesInGroup[firstIndexOfRowWrtFilesInGroup + i]
                                .tag,
                      ),
                      file: filesInGroup[firstIndexOfRowWrtFilesInGroup + i],
                      selectedFiles: selectedFiles,
                      limitSelectionToOne: limitSelectionToOne,
                      tag: tagPrefix,
                      photoGridSize: crossAxisCount,
                      currentUserID: currentUserID,
                    ),
                  );

                  endOfListReached =
                      filesInGroup[firstIndexOfRowWrtFilesInGroup + i] ==
                          lastFile;
                  i++;
                }
              } else {
                for (int i = 0; i < crossAxisCount; i++) {
                  gridRowChildren.add(
                    GalleryFileWidget(
                      key: ValueKey(
                        tagPrefix +
                            filesInGroup[firstIndexOfRowWrtFilesInGroup + i]
                                .tag,
                      ),
                      file: filesInGroup[firstIndexOfRowWrtFilesInGroup + i],
                      selectedFiles: selectedFiles,
                      limitSelectionToOne: limitSelectionToOne,
                      tag: tagPrefix,
                      photoGridSize: crossAxisCount,
                      currentUserID: currentUserID,
                    ),
                  );
                }
              }

              return FixedExtentGridRow(
                width: tileHeight,
                height: tileHeight,
                spacing: spacing,
                textDirection: TextDirection.ltr,
                children: gridRowChildren,
              );
            }
          },
        ),
      );

      _scrollOffsetToGroupIdMap[currentOffset] = groupID;
      _groupIdToScrollOffsetMap[groupID] = currentOffset;
      _groupScrollOffsets.add(currentOffset);

      currentIndex = lastIndex;
      currentOffset = maxOffset;
    }

    _logger.info(
      "Built group layouts in ${stopwatch.elapsedMilliseconds} ms",
    );
    print(
      "Built group layouts in ${stopwatch.elapsedMilliseconds} ms",
    );
    stopwatch.stop();

    return groupLayouts;
  }

// TODO: compute this in isolate
  void _buildGroups() {
    final stopwatch = Stopwatch()..start();

    final yearsInGroups = <int>{}; //Only relevant for time grouping
    List<EnteFile> groupFiles = [];
    final allFilesLength = allFiles.length;

    if (groupType.showGroupHeader()) {
      for (int index = 0; index < allFilesLength; index++) {
        if (index > 0 &&
            !groupType.areFromSameGroup(allFiles[index - 1], allFiles[index])) {
          _createNewGroup(groupFiles, yearsInGroups);
          groupFiles = [];
        }
        groupFiles.add(allFiles[index]);
      }
      if (groupFiles.isNotEmpty) {
        _createNewGroup(groupFiles, yearsInGroups);
      }
    } else {
// Split allFiles into groups of max length 10 * crossAxisCount for
      // better performance since SectionedSliverList is used.
      for (int i = 0; i < allFiles.length; i += 10 * crossAxisCount) {
        final end = (i + 10 * crossAxisCount < allFiles.length)
            ? i + 10 * crossAxisCount
            : allFiles.length;
        final subGroup = allFiles.sublist(i, end);
        _createNewGroup(subGroup, yearsInGroups);
      }
    }

    _logger.info(
      "Built ${_groupIds.length} groups for group type ${groupType.name} in ${stopwatch.elapsedMilliseconds} ms",
    );
    print(
      "Built ${_groupIds.length} groups for group type ${groupType.name} in ${stopwatch.elapsedMilliseconds} ms",
    );
    stopwatch.stop();
  }

  void _createNewGroup(
    List<EnteFile> groupFiles,
    Set<int> yearsInGroups,
  ) {
    final uuid = _uuid.v1();
    _groupIds.add(uuid);
    _groupIdToFilesMap[uuid] = groupFiles;
    _groupIdToHeaderDataMap[uuid] = GroupHeaderData(
      groupType: groupType,
    );

    // For scrollbar divisions
    if (groupType.timeGrouping()) {
      final yearOfGroup = DateTime.fromMicrosecondsSinceEpoch(
        groupFiles.first.creationTime!,
      ).year;
      if (!yearsInGroups.contains(yearOfGroup)) {
        yearsInGroups.add(yearOfGroup);
        _scrollbarDivisions.add(
          ScrollbarDivision(
            groupID: uuid,
            title: yearOfGroup.toString(),
          ),
        );
      }
    }
  }
}

class GroupHeaderData {
  final GroupType groupType;

  GroupHeaderData({
    required this.groupType,
  });
}
