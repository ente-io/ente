class SmartAlbumConfig {
  final int collectionId;
  // person ids
  final Set<String> personIDs;
  // person id mapped with updatedat, file ids
  final Map<String, (int, Set<int>)> addedFiles;

  SmartAlbumConfig({
    required this.collectionId,
    required this.personIDs,
    required this.addedFiles,
  });

  Future<SmartAlbumConfig> getUpdatedConfig(Set<String> newPersonsIds) async {
    final toAdd = newPersonsIds.difference(personIDs);
    final toRemove = personIDs.difference(newPersonsIds);
    final newFiles = Map<String, (int, Set<int>)>.from(addedFiles);

    // Remove whats not needed
    for (final personId in toRemove) {
      newFiles.remove(personId);
    }

    // Add files which are needed
    for (final personId in toAdd) {
      newFiles[personId] = (0, {});
    }

    return SmartAlbumConfig(
      collectionId: collectionId,
      personIDs: newPersonsIds,
      addedFiles: newFiles,
    );
  }

  Future<SmartAlbumConfig> addFiles(
    String personId,
    int updatedAt,
    Set<int> fileId,
  ) async {
    if (!addedFiles.containsKey(personId)) {
      return this;
    }

    final newFiles = Map<String, (int, Set<int>)>.from(addedFiles);
    newFiles[personId] = (
      updatedAt,
      newFiles[personId]!.$2.union(fileId),
    );
    return SmartAlbumConfig(
      collectionId: collectionId,
      personIDs: personIDs,
      addedFiles: newFiles,
    );
  }
}
