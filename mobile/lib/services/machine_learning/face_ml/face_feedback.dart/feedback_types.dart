enum FeedbackType {
  removePhotosClusterFeedback,
  addPhotosClusterFeedback,
  deleteClusterFeedback,
  mergeClusterFeedback,
  renameOrCustomThumbnailClusterFeedback; // I have merged renameClusterFeedback and customThumbnailClusterFeedback, since I suspect they will be used together often

  factory FeedbackType.fromValueString(String value) {
    switch (value) {
      case 'deleteClusterFeedback':
        return FeedbackType.deleteClusterFeedback;
      case 'mergeClusterFeedback':
        return FeedbackType.mergeClusterFeedback;
      case 'renameOrCustomThumbnailClusterFeedback':
        return FeedbackType.renameOrCustomThumbnailClusterFeedback;
      case 'removePhotoClusterFeedback':
        return FeedbackType.removePhotosClusterFeedback;
      case 'addPhotoClusterFeedback':
        return FeedbackType.addPhotosClusterFeedback;
      default:
        throw Exception('Invalid FeedbackType: $value');
    }
  }

  String toValueString() => name;
}
