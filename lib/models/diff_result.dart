class DiffResult {
  final int sharedFileNew,
      sharedFileUpdated,
      localUploadedFromDevice,
      localButUpdatedOnDevice,
      remoteNewFile;

  DiffResult(
    this.sharedFileNew,
    this.sharedFileUpdated,
    this.localUploadedFromDevice,
    this.localButUpdatedOnDevice,
    this.remoteNewFile,
  );
}
