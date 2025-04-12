import "package:photos/models/location/location.dart";

class MetadataResult {
  final DroidMetadata? droid;
  final IOSMetadata? iOSMetadata;
  final int processedState;

  MetadataResult({
    this.droid,
    this.iOSMetadata,
    required this.processedState,
  });
}

class DroidMetadata {
  int creationTime;
  int modificationTime;
  String hash;
  int size;
  Location? location;
  bool? isPanorama;
  int? mviIndex;
  DroidMetadata({
    required this.hash,
    required this.size,
    required this.creationTime,
    required this.modificationTime,
    this.mviIndex,
    this.location,
    this.isPanorama,
  });
}

class IOSMetadata {
  // https://developer.apple.com/documentation/photos/phcloudidentifier
  // Bulk mapping from local to cloud identifiers & vice versa
  String? cloudIdentifier;
  // https://developer.apple.com/documentation/photos/phassetsourcetype
  int? sourceType;
  bool? hasAdjustments;
  String? adjustmentFormatIdentifier;
  bool? representsBurst;
  String? burstIdentifier;
  int? burstSelectionTypes;
}
