import "package:photos/models/file/file.dart";
import "package:photos/models/ignored_upload_reason.dart";

class IgnoredUpload {
  final EnteFile file;
  final String reason;
  final IgnoredUploadReasonBucket reasonBucket;

  IgnoredUpload({required this.file, required this.reason})
    : reasonBucket = ignoredUploadReasonBucketFor(reason);
}
