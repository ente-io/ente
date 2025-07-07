class RLMapping {
  final int remoteUploadID;
  final String localID;
  final String? localCloudID;
  final MatchType mappingType;

  RLMapping({
    required this.remoteUploadID,
    required this.localID,
    required this.localCloudID,
    required this.mappingType,
  });

  List<Object?> get rowValues => [
        remoteUploadID,
        localID,
        localCloudID,
        mappingType.name,
      ];
}

enum MatchType {
  localID,
  cloudID,
  deviceUpload,
  deviceHashMatched,
}

extension MappingTypeExtension on MatchType {
  String get name {
    switch (this) {
      case MatchType.localID:
        return "localID";
      case MatchType.cloudID:
        return "cloudID";
      case MatchType.deviceUpload:
        return "deviceUpload";
      case MatchType.deviceHashMatched:
        return "deviceHashMatched";
    }
  }

  static MatchType fromName(String name) {
    switch (name) {
      case "localID":
        return MatchType.localID;
      case "cloudID":
        return MatchType.cloudID;
      case "deviceUpload":
        return MatchType.deviceUpload;
      case "deviceHashMatched":
        return MatchType.deviceHashMatched;
      default:
        throw Exception("Unknown mapping type: $name");
    }
  }
}
