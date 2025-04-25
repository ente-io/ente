enum MappingType {
  remote,
  cloudIdMatched,
  deviceUpload,
  deviceHashMatched,
}

extension MappingTypeExtension on MappingType {
  String get name {
    switch (this) {
      case MappingType.remote:
        return "remote";
      case MappingType.cloudIdMatched:
        return "cloudIdMatched";
      case MappingType.deviceUpload:
        return "deviceUpload";
      case MappingType.deviceHashMatched:
        return "deviceHashMatched";
    }
  }

  MappingType fromName(String name) {
    switch (name) {
      case "remote":
        return MappingType.remote;
      case "cloudIdMatched":
        return MappingType.cloudIdMatched;
      case "deviceUpload":
        return MappingType.deviceUpload;
      case "deviceHashMatched":
        return MappingType.deviceHashMatched;
      default:
        throw Exception("Unknown mapping type: $name");
    }
  }
}

class UploadLocalMapping {
  final int remoteUploadID;
  final String localID;
  final String? localCloudID;
  final MappingType mappingType;

  UploadLocalMapping({
    required this.remoteUploadID,
    required this.localID,
    required this.localCloudID,
    required this.mappingType,
  });
}
