class BackupStatus {
  final List<String> localIDs;
  final int size;

  BackupStatus(this.localIDs, this.size);
}

class BackedUpFileIDs {
  final List<String> localIDs;
  final List<int> uploadedIDs;

  BackedUpFileIDs(this.localIDs, this.uploadedIDs);
}
