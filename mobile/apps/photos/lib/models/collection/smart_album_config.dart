typedef PersonInfo = ({int updatedAt, Set<int> addedFiles});

class SmartAlbumConfig {
  // A nullable remote ID for syncing purposes
  final String? remoteId;

  final int collectionId;
  // person ids
  final Set<String> personIDs;
  // person id mapped with updatedat, file ids
  final Map<String, PersonInfo> infoMap;
  final int updatedAt;

  SmartAlbumConfig({
    this.remoteId,
    required this.collectionId,
    required this.personIDs,
    required this.infoMap,
    this.updatedAt = 0,
  });

  Future<SmartAlbumConfig> getUpdatedConfig(Set<String> newPersonsIds) async {
    final toAdd = newPersonsIds.difference(personIDs);
    final toRemove = personIDs.difference(newPersonsIds);
    final newInfoMap = Map<String, PersonInfo>.from(infoMap);

    // Remove whats not needed
    for (final personId in toRemove) {
      newInfoMap.remove(personId);
    }

    // Add files which are needed
    for (final personId in toAdd) {
      newInfoMap[personId] = (updatedAt: 0, addedFiles: <int>{});
    }

    return SmartAlbumConfig(
      remoteId: remoteId,
      collectionId: collectionId,
      personIDs: newPersonsIds,
      infoMap: newInfoMap,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<SmartAlbumConfig> addFiles(
    String personId,
    int updatedAt,
    Set<int> fileId,
  ) async {
    if (!infoMap.containsKey(personId)) {
      return this;
    }

    final newInfoMap = Map<String, PersonInfo>.from(infoMap);
    newInfoMap[personId] = (
      updatedAt: updatedAt,
      addedFiles: newInfoMap[personId]!.addedFiles.union(fileId),
    );
    return SmartAlbumConfig(
      remoteId: remoteId,
      collectionId: collectionId,
      personIDs: personIDs,
      infoMap: newInfoMap,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // toJson and fromJson methods
  Map<String, dynamic> toJson() {
    return {
      "collection_id": collectionId,
      "person_ids": personIDs.toList(),
      "info_map": infoMap.map(
        (key, value) => MapEntry(
          key,
          {
            "updated_at": value.updatedAt,
            "added_files": value.addedFiles.toList(),
          },
        ),
      ),
    };
  }

  factory SmartAlbumConfig.fromJson(
    Map<String, dynamic> json,
    String? remoteId,
    int? updatedAt,
  ) {
    final personIDs = Set<String>.from(json["person_ids"] as List);
    final infoMap = (json["info_map"] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        (
          updatedAt: value["updated_at"] as int,
          addedFiles: Set<int>.from(value["added_files"] as List),
        ),
      ),
    );

    return SmartAlbumConfig(
      remoteId: remoteId,
      collectionId: json["collection_id"] as int,
      personIDs: personIDs,
      infoMap: infoMap,
      updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  SmartAlbumConfig merge(SmartAlbumConfig b) {
    if (remoteId == b.remoteId) {
      if (updatedAt >= b.updatedAt) {
        return this;
      }
      return b;
    }
    return SmartAlbumConfig(
      remoteId: b.updatedAt <= updatedAt ? b.remoteId : remoteId,
      collectionId: b.collectionId,
      personIDs: personIDs.union(b.personIDs),
      infoMap: {
        ...infoMap,
        ...b.infoMap.map(
          (key, value) => MapEntry(
            key,
            (
              updatedAt: infoMap[key]?.updatedAt != null &&
                      infoMap[key]!.updatedAt > value.updatedAt
                  ? infoMap[key]!.updatedAt
                  : value.updatedAt,
              addedFiles: infoMap[key]?.addedFiles.union(value.addedFiles) ??
                  value.addedFiles,
            ),
          ),
        ),
      },
    );
  }
}
