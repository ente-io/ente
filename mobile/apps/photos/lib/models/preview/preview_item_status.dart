enum PreviewItemStatus {
  // in progress
  compressing,
  uploading,
  // error
  failed,
  // queued
  inQueue,
  retry,
  // done
  uploaded,
  // paused (e.g., due to uploads in progress)
  paused,
}
