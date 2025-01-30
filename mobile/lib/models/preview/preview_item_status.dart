enum PreviewItemStatus {
  // queued
  inQueue,
  retry,
  // in progress
  compressing,
  uploading,
  // error
  failed,
  // done
  uploaded,
}
