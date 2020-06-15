class PhotoUploadEvent {
  final int completed;
  final int total;
  final bool hasError;

  PhotoUploadEvent({this.completed, this.total, this.hasError = false});
}
