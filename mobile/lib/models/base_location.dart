import "dart:convert";

import "package:photos/models/file/file.dart";
import "package:photos/models/location/location.dart";

const baseRadius = 0.6;

class BaseLocation {
  final List<EnteFile> files;
  int? firstCreationTime;
  int? lastCreationTime;
  final Location location;
  final bool isCurrentBase;

  BaseLocation(
    this.files,
    this.location,
    this.isCurrentBase, {
    this.firstCreationTime,
    this.lastCreationTime,
  });

  static List<BaseLocation> decodeJsonToList(
    String jsonString,
    Map<int, EnteFile> filesMap,
  ) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList
        .map((json) => BaseLocation.fromJson(json, filesMap))
        .toList();
  }

  static String encodeListToJson(List<BaseLocation> baseLocations) {
    final jsonList =
        baseLocations.map((location) => location.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static BaseLocation fromJson(
    Map<String, dynamic> json,
    Map<int, EnteFile> filesMap,
  ) {
    return BaseLocation(
      (json['fileIDs'] as List).map((e) => filesMap[e]!).toList(),
      Location(
        latitude: json['location']['latitude'],
        longitude: json['location']['longitude'],
      ),
      json['isCurrentBase'] as bool,
      firstCreationTime: json['firstCreationTime'] as int?,
      lastCreationTime: json['lastCreationTime'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileIDs': files
          .where((file) => file.uploadedFileID != null)
          .map((file) => file.uploadedFileID!)
          .toList(),
      'location': {
        'latitude': location.latitude!,
        'longitude': location.longitude!,
      },
      'isCurrentBase': isCurrentBase,
      'firstCreationTime': firstCreationTime,
      'lastCreationTime': lastCreationTime,
    };
  }

  int averageCreationTime() {
    if (firstCreationTime != null && lastCreationTime != null) {
      return (firstCreationTime! + lastCreationTime!) ~/ 2;
    }
    final List<int> creationTimes = files
        .where((file) => file.creationTime != null)
        .map((file) => file.creationTime!)
        .toList();
    if (creationTimes.length < 2) {
      return creationTimes.isEmpty ? 0 : creationTimes.first;
    }
    creationTimes.sort();
    firstCreationTime ??= creationTimes.first;
    lastCreationTime ??= creationTimes.last;
    return (firstCreationTime! + lastCreationTime!) ~/ 2;
  }

  BaseLocation copyWith({
    List<EnteFile>? files,
    int? firstCreationTime,
    int? lastCreationTime,
    Location? location,
    bool? isCurrentBase,
  }) {
    return BaseLocation(
      files ?? this.files,
      location ?? this.location,
      isCurrentBase ?? this.isCurrentBase,
      firstCreationTime: firstCreationTime ?? this.firstCreationTime,
      lastCreationTime: lastCreationTime ?? this.lastCreationTime,
    );
  }
}
