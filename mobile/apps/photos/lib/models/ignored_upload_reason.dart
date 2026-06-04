import "package:photos/models/ignored_file.dart";
import "package:photos/utils/apple_photos_errors.dart";

enum IgnoredUploadReasonBucket {
  all,
  iCloudUnavailable,
  deletedFromEnte,
  other,
}

const ignoredUploadReasonBuckets = <IgnoredUploadReasonBucket>[
  IgnoredUploadReasonBucket.all,
  IgnoredUploadReasonBucket.iCloudUnavailable,
  IgnoredUploadReasonBucket.deletedFromEnte,
  IgnoredUploadReasonBucket.other,
];

IgnoredUploadReasonBucket ignoredUploadReasonBucketFor(String reason) {
  if (reason == phPhotosResourceUnavailableReason) {
    return IgnoredUploadReasonBucket.iCloudUnavailable;
  }
  if (reason == kIgnoreReasonTrash) {
    return IgnoredUploadReasonBucket.deletedFromEnte;
  }
  return IgnoredUploadReasonBucket.other;
}
