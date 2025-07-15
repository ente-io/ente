typedef PersonInfo = ({int updatedAt, Set<int> addedFiles});

class SmartAlbumConfig {
  final int collectionId;
  // person ids
  final Set<String> personIDs;
  // person id mapped with updatedat, file ids
  final Map<String, PersonInfo> infoMap;

  SmartAlbumConfig({
    required this.collectionId,
    required this.personIDs,
    required this.infoMap,
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
      collectionId: collectionId,
      personIDs: newPersonsIds,
      infoMap: newInfoMap,
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
      collectionId: collectionId,
      personIDs: personIDs,
      infoMap: newInfoMap,
    );
  }
}
