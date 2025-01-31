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
}
