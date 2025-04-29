import "package:photos/module/upload/model/xml.dart";

class PartETag extends XmlParsableObject {
  final int partNumber;
  final String eTag;

  PartETag(this.partNumber, this.eTag);

  @override
  String get elementName => "Part";

  @override
  Map<String, dynamic> toMap() {
    return {
      "PartNumber": partNumber,
      "ETag": eTag,
    };
  }
}

enum MultipartStatus {
  pending,
  uploaded,
  completed,
}

enum PartStatus {
  pending,
  uploaded,
}

class MultipartInfo {
  final List<bool>? partUploadStatus;
  final Map<int, String>? partETags;
  final int? partSize;
  final int encFileSize;
  final MultipartUploadURLs urls;
  final MultipartStatus status;

  MultipartInfo({
    this.partUploadStatus,
    this.partETags,
    this.partSize,
    this.status = MultipartStatus.pending,
    required this.encFileSize,
    required this.urls,
  });
}

class MultipartUploadURLs {
  final String objectKey;
  final List<String> partsURLs;
  final String completeURL;

  MultipartUploadURLs({
    required this.objectKey,
    required this.partsURLs,
    required this.completeURL,
  });

  factory MultipartUploadURLs.fromMap(Map<String, dynamic> map) {
    return MultipartUploadURLs(
      objectKey: map["urls"]["objectKey"],
      partsURLs: (map["urls"]["partURLs"] as List).cast<String>(),
      completeURL: map["urls"]["completeURL"],
    );
  }
}
