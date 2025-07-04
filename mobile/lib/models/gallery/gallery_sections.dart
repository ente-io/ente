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
    this.limitSelectionToOne = false,
  }) {
    init();
  }

  final List<String> _groupIds = [];
  final Map<String, List<EnteFile>> _groupIdToFilesMap = {};
  final Map<String, GroupHeaderData> _groupIdToHeaderDataMap = {};
  late final int crossAxisCount;
  final currentUserID = Configuration.instance.getUserID();
  static const double spacing = 2.0;

  List<String> get groupIDs => _groupIds;
  Map<String, List<EnteFile>> get groupIDToFilesMap => _groupIdToFilesMap;
  Map<String, GroupHeaderData> get groupIdToheaderDataMap =>
      _groupIdToHeaderDataMap;

  final _uuid = const Uuid();

  void init() {
    final stopwatch = Stopwatch()..start();
    _buildGroups();
    _logger.info(
      "Built ${_groupIds.length} groups in ${stopwatch.elapsedMilliseconds} ms",
    );
    print(
      "Built ${_groupIds.length} groups in ${stopwatch.elapsedMilliseconds} ms",
    );
    stopwatch.stop();

    crossAxisCount = localSettings.getPhotoGridSize();
  }

  List<FixedExtentSectionLayout> getGroupLayouts() {
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
