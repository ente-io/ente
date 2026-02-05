class FreeableSpaceInfo {
  final List<String> localIDs;
  final int size;

  FreeableSpaceInfo(this.localIDs, this.size);
}

class FreeableFileIDs {
  final List<String> localIDs;
  final List<int> uploadedIDs;
  // localSize indicates the approximate size of the files on the device.
  // The size may not be exact because the remoteFile is encrypted before
  // uploaded
  final int localSize;

  FreeableFileIDs(this.localIDs, this.uploadedIDs, this.localSize);
}
