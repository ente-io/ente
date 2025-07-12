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
import "package:uuid/uuid.dart";

class GalleryGroups {
  final List<EnteFile> allFiles;
  final GroupType groupType;
  final SelectedFiles? selectedFiles;
  final bool limitSelectionToOne;
  final String tagPrefix;
  final bool showSelectAllByDefault;
  final _logger = Logger("GalleryGroups");

  //TODO: Add support for sort order
  final bool sortOrderAsc;
  final double widthAvailable;
  final double headerExtent;
  GalleryGroups({
    required this.allFiles,
    required this.groupType,
    required this.widthAvailable,
    required this.selectedFiles,
    required this.tagPrefix,
    this.sortOrderAsc = true,
    required this.headerExtent,
    required this.showSelectAllByDefault,
    this.limitSelectionToOne = false,
  }) {
    init();
  }

  static const double spacing = 2.0;

  late final int crossAxisCount;
  late final List<FixedExtentSectionLayout> _groupLayouts;

  final List<String> _groupIds = [];
  final Map<String, List<EnteFile>> _groupIdToFilesMap = {};
  final Map<String, GroupHeaderData> _groupIdToHeaderDataMap = {};
  final Map<double, String> _scrollOffsetToGroupIdMap = {};
  final List<double> _groupScrollOffsets = [];
  final currentUserID = Configuration.instance.getUserID();
  final _uuid = const Uuid();

  List<String> get groupIDs => _groupIds;
  Map<String, List<EnteFile>> get groupIDToFilesMap => _groupIdToFilesMap;
  Map<String, GroupHeaderData> get groupIdToheaderDataMap =>
      _groupIdToHeaderDataMap;
  Map<double, String> get scrollOffsetToGroupIdMap => _scrollOffsetToGroupIdMap;
  List<FixedExtentSectionLayout> get groupLayouts => _groupLayouts;
  List<double> get groupScrollOffsets => _groupScrollOffsets;

  void init() {
    _buildGroups();
    crossAxisCount = localSettings.getPhotoGridSize();
    _groupLayouts = _computeGroupLayouts();
    assert(groupIDs.length == _groupIdToFilesMap.length);
    assert(groupIDs.length == _groupIdToHeaderDataMap.length);
    assert(
      groupIDs.length == _scrollOffsetToGroupIdMap.length,
    );
    assert(groupIDs.length == _groupScrollOffsets.length);
  }

  List<FixedExtentSectionLayout> _computeGroupLayouts() {
    final stopwatch = Stopwatch()..start();
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
          headerExtent;
      final bodyFirstIndex = firstIndex + 1;

      groupLayouts.add(
        FixedExtentSectionLayout(
          firstIndex: firstIndex,
          lastIndex: lastIndex,
          minOffset: minOffset,
          maxOffset: maxOffset,
          headerExtent: headerExtent,
          tileHeight: tileHeight,
          spacing: spacing,
          builder: (context, rowIndex) {
            if (rowIndex == firstIndex) {
              return GroupHeaderWidget(
                title: _groupIdToHeaderDataMap[groupID]!
                    .groupType
                    .getTitle(context, groupIDToFilesMap[groupID]!.first),
                gridSize: crossAxisCount,
                filesInGroup: groupIDToFilesMap[groupID]!,
                selectedFiles: selectedFiles,
                showSelectAllByDefault: showSelectAllByDefault,
              );
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
    List<EnteFile> groupFiles = [];
    for (int index = 0; index < allFiles.length; index++) {
      if (index > 0 &&
          !groupType.areFromSameGroup(allFiles[index - 1], allFiles[index])) {
        _createNewGroup(groupFiles);
        groupFiles = [];
      }
      groupFiles.add(allFiles[index]);
    }
    if (groupFiles.isNotEmpty) {
      _createNewGroup(groupFiles);
    }
    _logger.info(
      "Built ${_groupIds.length} groups in ${stopwatch.elapsedMilliseconds} ms",
    );
    print(
      "Built ${_groupIds.length} groups in ${stopwatch.elapsedMilliseconds} ms",
    );
    stopwatch.stop();
  }

  void _createNewGroup(
    List<EnteFile> groupFiles,
  ) {
    final uuid = _uuid.v1();
    _groupIds.add(uuid);
    _groupIdToFilesMap[uuid] = groupFiles;
    _groupIdToHeaderDataMap[uuid] = GroupHeaderData(
      groupType: groupType,
    );
  }
}

class GroupHeaderData {
  final GroupType groupType;

  GroupHeaderData({
    required this.groupType,
  });
}
