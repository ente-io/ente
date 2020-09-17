class PhotoUploadEvent {
  final int completed;
  final int total;
  final bool hasError;
  final bool wasStopped;

  PhotoUploadEvent({
    this.completed,
    this.total,
    this.hasError = false,
    this.wasStopped = false,
  });
}
