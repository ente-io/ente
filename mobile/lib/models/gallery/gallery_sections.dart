import "dart:core";

import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/gallery/fixed_extent_grid_row.dart";
import "package:photos/models/gallery/fixed_extent_section_layout.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:uuid/uuid.dart";

class GallerySections {
  final List<EnteFile> allFiles;
  final GroupType groupType;

  //TODO: Add support for sort order
  final bool sortOrderAsc;
  final double widthAvailable;
  final double headerExtent;
  final BuildContext context;
  GallerySections({
    required this.allFiles,
    required this.groupType,
    required this.widthAvailable,
    required this.context,
    this.sortOrderAsc = true,
    this.headerExtent = 85,
  }) {
    init();
  }

  final List<String> _groupIDs = [];
  final Map<String, List<EnteFile>> _groupIDToFilesMap = {};
  final Map<String, GroupHeaderData> _groupIdToheaderDataMap = {};
  late final int crossAxisCount;

  List<String> get groupIDs => _groupIDs;
  Map<String, List<EnteFile>> get groupIDToFilesMap => _groupIDToFilesMap;
  Map<String, GroupHeaderData> get groupIdToheaderDataMap =>
      _groupIdToheaderDataMap;

  final _uuid = const Uuid();

  void init() {
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

    crossAxisCount = localSettings.getPhotoGridSize();
  }

  void _createNewGroup(
    List<EnteFile> dailyFiles,
  ) {
    final uuid = _uuid.v1();
    _groupIDs.add(uuid);
    _groupIDToFilesMap[uuid] = dailyFiles;
    _groupIdToheaderDataMap[uuid] = GroupHeaderData(
      title: groupType.getTitle(
        context,
        dailyFiles.first,
        lastFile: dailyFiles.last,
      ),
      groupType: groupType,
    );
  }

  List<FixedExtentSectionLayout> getSectionLayouts() {
    int currentIndex = 0;
    double currentOffset = 0.0;
    final tileHeight = widthAvailable / crossAxisCount;
    final sectionLayouts = <FixedExtentSectionLayout>[];

    // TODO: spacing
    for (final key in _groupIDToFilesMap.keys) {
      final filesInGroup = _groupIDToFilesMap[key]!;
      final numberOfGridRows = (filesInGroup.length / crossAxisCount).ceil();
      final firstIndex = currentIndex == 0 ? currentIndex : currentIndex + 1;
      final lastIndex = firstIndex + numberOfGridRows;
      final minOffset = currentOffset;
      final maxOffset =
          minOffset + (numberOfGridRows * tileHeight) + headerExtent;

      int currentGroupIndex = 0;
      sectionLayouts.add(
        FixedExtentSectionLayout(
          firstIndex: firstIndex,
          lastIndex: lastIndex,
          minOffset: minOffset,
          maxOffset: maxOffset,
          headerExtent: headerExtent,
          tileHeight: tileHeight,
          spacing: 0,
          builder: (context, index) {
            if (index == firstIndex) {
              return SizedBox(
                height: headerExtent,
                child: Placeholder(
                  child: Text(_groupIdToheaderDataMap[key]!.title),
                ),
              );
            } else {
              final gridRowChildren = <Widget>[];
              for (int i in Iterable<int>.generate(crossAxisCount)) {
                if (currentGroupIndex < filesInGroup.length) {
                  gridRowChildren.add(
                    SizedBox(
                      width: tileHeight,
                      height: tileHeight,
                      child: Text(
                        i.toString(),
                      ),
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
                //TODO: spacing
                spacing: 0,
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

    return sectionLayouts;
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
