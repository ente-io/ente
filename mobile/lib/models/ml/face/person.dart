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
  final bool isHidden;
  String? avatarFaceID;
  List<ClusterInfo>? assigned = List<ClusterInfo>.empty();
  List<ClusterInfo>? rejected = List<ClusterInfo>.empty();
  final String? birthDate;

  bool hasAvatar() => avatarFaceID != null;

  bool get isIgnored =>
      (name.isEmpty || name == '(hidden)' || name == '(ignored)');

  PersonData({
    required this.name,
    this.assigned,
    this.rejected,
    this.avatarFaceID,
    this.isHidden = false,
    this.birthDate,
  });
  // copyWith
  PersonData copyWith({
    String? name,
    List<ClusterInfo>? assigned,
    String? avatarFaceId,
    bool? isHidden,
    int? version,
    String? birthDate,
  }) {
    return PersonData(
      name: name ?? this.name,
      assigned: assigned ?? this.assigned,
      avatarFaceID: avatarFaceId ?? this.avatarFaceID,
      isHidden: isHidden ?? this.isHidden,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  void logStats() {
    if (kDebugMode == false) return;
    // log number of assigned and rejected clusters and total number of faces in each cluster
    final StringBuffer sb = StringBuffer();
    sb.writeln('Person: $name');
    int assignedCount = 0;
    for (final a in (assigned ?? <ClusterInfo>[])) {
      assignedCount += a.faces.length;
    }
    sb.writeln('Assigned: ${assigned?.length} withFaces $assignedCount');
    sb.writeln('Rejected: ${rejected?.length}');
    if (assigned != null) {
      for (var cluster in assigned!) {
        sb.writeln('Cluster: ${cluster.id} - ${cluster.faces.length}');
      }
    }
    debugPrint(sb.toString());
  }

  // toJson
  Map<String, dynamic> toJson() => {
        'name': name,
        'assigned': assigned?.map((e) => e.toJson()).toList(),
        'rejected': rejected?.map((e) => e.toJson()).toList(),
        'avatarFaceID': avatarFaceID,
        'isHidden': isHidden,
        'birthDate': birthDate,
      };

  // fromJson
  factory PersonData.fromJson(Map<String, dynamic> json) {
    final assigned = (json['assigned'] == null || json['assigned'].length == 0)
        ? <ClusterInfo>[]
        : List<ClusterInfo>.from(
            json['assigned'].map((x) => ClusterInfo.fromJson(x)),
          );

    final rejected = (json['rejected'] == null || json['rejected'].length == 0)
        ? <ClusterInfo>[]
        : List<ClusterInfo>.from(
            json['rejected'].map((x) => ClusterInfo.fromJson(x)),
          );
    return PersonData(
      name: json['name'] as String,
      assigned: assigned,
      rejected: rejected,
      avatarFaceID: json['avatarFaceID'] as String?,
      isHidden: json['isHidden'] as bool? ?? false,
      birthDate: json['birthDate'] as String?,
    );
  }
}
