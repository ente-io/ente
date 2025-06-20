import "dart:core";

import "package:photos/models/file/file.dart";
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:uuid/uuid.dart";

class GallerySections {
  final List<EnteFile> allFiles;
  final GroupType groupType;
  final bool sortOrderAsc;
  GallerySections({
    required this.allFiles,
    required this.groupType,
    this.sortOrderAsc = true,
  });

  late final List<String> _groupIDs;
  late final Map<String, List<EnteFile>> _groupIDToFilesMap;
  late Map<String, GroupHeaderData> _groupIdToheaderDataMap;

  List<String> get groupIDs => _groupIDs;
  Map<String, List<EnteFile>> get groupIDToFilesMap => _groupIDToFilesMap;
  Map<String, GroupHeaderData> get groupIdToheaderDataMap =>
      _groupIdToheaderDataMap;

  final _uuid = const Uuid();

  void init() {
    List<EnteFile> dailyFiles = [];
    for (int index = 0; index < allFiles.length; index++) {
      if (index > 0 &&
          groupType.areFromSameGroup(allFiles[index - 1], allFiles[index])) {
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
    _groupIDs.add(uuid);
    _groupIDToFilesMap[uuid] = dailyFiles;
    _groupIdToheaderDataMap[uuid] = GroupHeaderData(
      title: dailyFiles.first.creationTime!.toString(),
    );
  }
}

class GroupHeaderData {
  final String title;

  GroupHeaderData({
    required this.title,
  });
}
