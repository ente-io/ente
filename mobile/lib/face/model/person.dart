// PersonEntity represents information about a Person in the context of FaceClustering that is stored.
// On the remote server, the PersonEntity is stored as {Entity} with type person.
// On the device, this information is stored as [LocalEntityData] with type person.
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
  final int id;
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
      id: json['id'] as int,
      faces: (json['faces'] as List<dynamic>).map((e) => e as String).toSet(),
    );
  }
}

class PersonData {
  final String name;
  final bool isHidden;
  String? avatarFaceId;
  List<ClusterInfo>? assigned = List<ClusterInfo>.empty();
  List<ClusterInfo>? rejected = List<ClusterInfo>.empty();
  final String? birthDate;

  bool hasAvatar() => avatarFaceId != null;

  PersonData({
    required this.name,
    this.assigned,
    this.rejected,
    this.avatarFaceId,
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
      avatarFaceId: avatarFaceId ?? this.avatarFaceId,
      isHidden: isHidden ?? this.isHidden,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  // toJson
  Map<String, dynamic> toJson() => {
        'name': name,
        'assigned': assigned?.map((e) => e.toJson()).toList(),
        'rejected': rejected?.map((e) => e.toJson()).toList(),
        'avatarFaceId': avatarFaceId,
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
      avatarFaceId: json['avatarFaceId'] as String?,
      isHidden: json['isHidden'] as bool? ?? false,
      birthDate: json['birthDate'] as String?,
    );
  }
}
