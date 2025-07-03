import "dart:core";

import "package:flutter/material.dart";
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

  //TODO: Add support for sort order
  final bool sortOrderAsc;
  final double widthAvailable;
  final double headerExtent;
  final BuildContext context;
  GalleryGroups({
    required this.allFiles,
    required this.groupType,
    required this.widthAvailable,
    required this.context,
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
    _buildGroups();
    crossAxisCount = localSettings.getPhotoGridSize();
  }

  List<FixedExtentSectionLayout> getGroupLayouts() {
    int currentIndex = 0;
    double currentOffset = 0.0;
    final tileHeight = widthAvailable / crossAxisCount;
    final groupLayouts = <FixedExtentSectionLayout>[];

    final groupIDs = _groupIdToFilesMap.keys;

    // TODO: spacing
    for (final groupID in groupIDs) {
      final filesInGroup = _groupIdToFilesMap[groupID]!;
      final numberOfGridRows = (filesInGroup.length / crossAxisCount).ceil();
      final firstIndex = currentIndex == 0 ? currentIndex : currentIndex + 1;
      final lastIndex = firstIndex + numberOfGridRows;
      final minOffset = currentOffset;
      final maxOffset =
          minOffset + (numberOfGridRows * tileHeight) + headerExtent;

      int currentGroupIndex = 0;
      groupLayouts.add(
        FixedExtentSectionLayout(
          firstIndex: firstIndex,
          lastIndex: lastIndex,
          minOffset: minOffset,
          maxOffset: maxOffset,
          headerExtent: headerExtent,
          tileHeight: tileHeight,
          spacing: spacing,
          builder: (context, index) {
            if (index == firstIndex) {
              return GroupHeaderWidget(
                title: _groupIdToHeaderDataMap[groupID]!.title,
                gridSize: crossAxisCount,
              );
            } else {
              final gridRowChildren = <Widget>[];
              for (int _ in Iterable<int>.generate(crossAxisCount)) {
                if (currentGroupIndex < filesInGroup.length) {
                  gridRowChildren.add(
                    GalleryFileWidget(
                      file: filesInGroup[currentGroupIndex],
                      selectedFiles: selectedFiles,
                      limitSelectionToOne: limitSelectionToOne,
                      tag: tagPrefix,
                      photoGridSize: crossAxisCount,
                      currentUserID: currentUserID,
                    ),
                  );
                  currentGroupIndex++;
                } else {
                  break;
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

      // Adding this crashes the app??????

      // if (groupID != groupIDs.last) {
      //   // lastIndex - (firstIndex + 1) - 1
      //   currentOffset = maxOffset + (lastIndex - firstIndex) * spacing;
      // }
      currentOffset = maxOffset;
    }

    return groupLayouts;
  }

  void _buildGroups() {
    List<EnteFile> dailyFiles = [];
    for (int index = 0; index < allFiles.length; index++) {
      if (index > 0 &&
          !groupType.areFromSameGroup(allFiles[index - 1], allFiles[index])) {
        _createNewGroup(dailyFiles);
        dailyFiles = [];
      }
      dailyFiles.add(allFiles[index]);
    }
    if (dailyFiles.isNotEmpty) {
      _createNewGroup(dailyFiles);
    }
  }

  void _createNewGroup(
    List<EnteFile> dailyFiles,
  ) {
    final uuid = _uuid.v1();
    _groupIds.add(uuid);
    _groupIdToFilesMap[uuid] = dailyFiles;
    _groupIdToHeaderDataMap[uuid] = GroupHeaderData(
      title: groupType.getTitle(
        context,
        dailyFiles.first,
        lastFile: dailyFiles.last,
      ),
      groupType: groupType,
    );
  }
}

class GroupHeaderData {
  final String title;
  final GroupType groupType;

  GroupHeaderData({
    required this.title,
    required this.groupType,
  });
}
