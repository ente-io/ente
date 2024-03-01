class BackupStatus {
  final List<String> localIDs;
  final int size;

  BackupStatus(this.localIDs, this.size);
}

class BackedUpFileIDs {
  final List<String> localIDs;
  final List<int> uploadedIDs;
  // localSize indicates the approximate size of the files on the device.
  // The size may not be exact because the remoteFile is encrypted before
  // uploaded
  final int localSize;

  BackedUpFileIDs(this.localIDs, this.uploadedIDs, this.localSize);
}
