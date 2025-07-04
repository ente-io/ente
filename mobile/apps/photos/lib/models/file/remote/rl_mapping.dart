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
        mappingType,
      ];
}

enum MatchType {
  remote,
  cloudIdMatched,
  deviceUpload,
  deviceHashMatched,
}

extension MappingTypeExtension on MatchType {
  String get name {
    switch (this) {
      case MatchType.remote:
        return "remote";
      case MatchType.cloudIdMatched:
        return "cloudIdMatched";
      case MatchType.deviceUpload:
        return "deviceUpload";
      case MatchType.deviceHashMatched:
        return "deviceHashMatched";
    }
  }

  static MatchType fromName(String name) {
    switch (name) {
      case "remote":
        return MatchType.remote;
      case "cloudIdMatched":
        return MatchType.cloudIdMatched;
      case "deviceUpload":
        return MatchType.deviceUpload;
      case "deviceHashMatched":
        return MatchType.deviceHashMatched;
      default:
        throw Exception("Unknown mapping type: $name");
    }
  }
}
