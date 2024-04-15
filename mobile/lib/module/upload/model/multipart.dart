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

class MultipartUploadURLs {
  final String objectKey;
  final List<String> partsURLs;
  final String completeURL;
  final List<bool>? partUploadStatus;
  final Map<int, String>? partETags;

  MultipartUploadURLs({
    required this.objectKey,
    required this.partsURLs,
    required this.completeURL,
    this.partUploadStatus,
    this.partETags,
  });

  factory MultipartUploadURLs.fromMap(Map<String, dynamic> map) {
    return MultipartUploadURLs(
      objectKey: map["urls"]["objectKey"],
      partsURLs: (map["urls"]["partURLs"] as List).cast<String>(),
      completeURL: map["urls"]["completeURL"],
    );
  }
}
