// PersonEntity represents information about a Person in the context of FaceClustering that is stored.
// On the remote server, the PersonEntity is stored as {Entity} with type person.
// On the device, this information is stored as [LocalEntityData] with type person.
import "package:flutter/foundation.dart";

class PersonEntity {
  final String remoteID;
  final PersonData data;
  PersonEntity(
    this.remoteID,
    this.data,
  );

  // copyWith
  PersonEntity copyWith({
    String? remoteID,
    PersonData? data,
  }) {
    return PersonEntity(
      remoteID ?? this.remoteID,
      data ?? this.data,
    );
  }
}

class ClusterInfo {
  final String id;
  final Set<String> faces;
  ClusterInfo({
    required this.id,
    required this.faces,
  });

  // toJson
  Map<String, dynamic> toJson() => {
        'id': id,
        'faces': faces.toList(),
      };

  // from Json
  factory ClusterInfo.fromJson(Map<String, dynamic> json) {
    return ClusterInfo(
      id: json['id'] as String,
      faces: (json['faces'] as List<dynamic>).map((e) => e as String).toSet(),
    );
  }
}

class PersonData {
  final String name;

  /// Used to mark a person to not show in the people section.
  /// WARNING: When checking whether to show a person, use [isIgnored] instead, as it also checks legacy hidden names.
  final bool isHidden;

  String? avatarFaceID;
  List<ClusterInfo> assigned = List<ClusterInfo>.empty();
  List<String> rejectedFaceIDs = List<String>.empty();

  /// string formatted in `yyyy-MM-dd`
  final String? birthDate;

  /// email should be always looked via userID as user might have changed
  /// their email ids.
  final String? email;
  final int? userID;

  bool hasAvatar() => avatarFaceID != null;

  /// Returns true if the person should be ignored in the UI.
  /// This included the regular [isHidden] check, but also a check for legacy names
  bool get isIgnored =>
      (isHidden || name.isEmpty || name == '(hidden)' || name == '(ignored)');

  PersonData({
    required this.name,
    this.assigned = const <ClusterInfo>[],
    this.rejectedFaceIDs = const <String>[],
    this.avatarFaceID,
    this.isHidden = false,
    this.birthDate,
    this.email,
    this.userID,
  });
  // copyWith
  PersonData copyWith({
    String? name,
    List<ClusterInfo>? assigned,
    String? avatarFaceId,
    bool? isHidden,
    int? version,
    String? birthDate,
    String? email,
    int? userID,
  }) {
    return PersonData(
      name: name ?? this.name,
      assigned: assigned ?? this.assigned,
      avatarFaceID: avatarFaceId ?? avatarFaceID,
      isHidden: isHidden ?? this.isHidden,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      userID: userID ?? this.userID,
    );
  }

  void logStats() {
    if (kDebugMode == false) return;
    // log number of assigned and rejected clusters and total number of faces in each cluster
    final StringBuffer sb = StringBuffer();
    sb.writeln('Person: $name');
    int assignedCount = 0;
    for (final a in assigned) {
      assignedCount += a.faces.length;
    }
    sb.writeln('Assigned: ${assigned.length} withFaces $assignedCount');
    sb.writeln('Rejected faceIDs: ${rejectedFaceIDs.length}');
    for (var cluster in assigned) {
      sb.writeln('Cluster: ${cluster.id} - ${cluster.faces.length}');
    }
    debugPrint(sb.toString());
  }

  // toJson
  Map<String, dynamic> toJson() => {
        'name': name,
        'assigned': assigned.map((e) => e.toJson()).toList(),
        'rejectedFaceIDs': rejectedFaceIDs,
        'avatarFaceID': avatarFaceID,
        'isHidden': isHidden,
        'birthDate': birthDate,
        'email': email,
        'userID': userID,
      };

  // fromJson
  factory PersonData.fromJson(Map<String, dynamic> json) {
    final assigned = (json['assigned'] == null ||
            json['assigned'].length == 0 ||
            json['assigned'] is! Iterable)
        ? <ClusterInfo>[]
        : List<ClusterInfo>.from(
            json['assigned']
                .where((x) => x is Map<String, dynamic>)
                .map((x) => ClusterInfo.fromJson(x as Map<String, dynamic>)),
          );

    final List<String> rejectedFaceIDs =
        (json['rejectedFaceIDs'] == null || json['rejectedFaceIDs'].length == 0)
            ? <String>[]
            : List<String>.from(
                json['rejectedFaceIDs'],
              );
    return PersonData(
      name: json['name'] as String,
      assigned: assigned,
      rejectedFaceIDs: rejectedFaceIDs,
      avatarFaceID: json['avatarFaceID'] as String?,
      isHidden: json['isHidden'] as bool? ?? false,
      birthDate: json['birthDate'] as String?,
      userID: json['userID'] as int?,
      email: json['email'] as String?,
    );
  }
}
