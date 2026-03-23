import "package:flutter/foundation.dart";
import "package:photos/models/ml/face/person.dart";

const Object _petDataUnchanged = Object();

class PetEntity {
  final String remoteID;
  final PetData data;
  PetEntity(
    this.remoteID,
    this.data,
  );

  PetEntity copyWith({
    String? remoteID,
    PetData? data,
  }) {
    return PetEntity(
      remoteID ?? this.remoteID,
      data ?? this.data,
    );
  }
}

class PetData {
  final String name;
  final int species;

  final bool isHidden;
  final bool isPinned;
  final bool hideFromMemories;

  String? avatarFaceID;
  List<ClusterInfo> assigned = List<ClusterInfo>.empty();
  List<String> rejectedFaceIDs = List<String>.empty();
  List<int> manuallyAssigned = List<int>.empty();

  /// string formatted in `yyyy-MM-dd`
  final String? birthDate;

  bool hasAvatar() => avatarFaceID != null;

  bool get isIgnored =>
      (isHidden || name.isEmpty || name == '(hidden)' || name == '(ignored)');

  PetData({
    required this.name,
    required this.species,
    this.assigned = const <ClusterInfo>[],
    this.rejectedFaceIDs = const <String>[],
    this.manuallyAssigned = const <int>[],
    this.avatarFaceID,
    this.isHidden = false,
    this.isPinned = false,
    this.hideFromMemories = false,
    this.birthDate,
  });

  PetData copyWith({
    String? name,
    int? species,
    List<ClusterInfo>? assigned,
    String? avatarFaceId,
    bool? isHidden,
    bool? isPinned,
    bool? hideFromMemories,
    Object? birthDate = _petDataUnchanged,
    List<String>? rejectedFaceIDs,
    List<int>? manuallyAssigned,
  }) {
    return PetData(
      name: name ?? this.name,
      species: species ?? this.species,
      assigned: assigned ?? this.assigned,
      avatarFaceID: avatarFaceId ?? avatarFaceID,
      isHidden: isHidden ?? this.isHidden,
      isPinned: isPinned ?? this.isPinned,
      hideFromMemories: hideFromMemories ?? this.hideFromMemories,
      birthDate: identical(birthDate, _petDataUnchanged)
          ? this.birthDate
          : birthDate as String?,
      rejectedFaceIDs:
          rejectedFaceIDs ?? List<String>.from(this.rejectedFaceIDs),
      manuallyAssigned:
          manuallyAssigned ?? List<int>.from(this.manuallyAssigned),
    );
  }

  void logStats() {
    if (kDebugMode == false) return;
    final StringBuffer sb = StringBuffer();
    sb.writeln('Pet: $name (species: $species)');
    int assignedCount = 0;
    for (final a in assigned) {
      assignedCount += a.faces.length;
    }
    sb.writeln('Assigned: ${assigned.length} withFaces $assignedCount');
    sb.writeln('Rejected faceIDs: ${rejectedFaceIDs.length}');
    sb.writeln('Manual fileIDs: ${manuallyAssigned.length}');
    for (var cluster in assigned) {
      sb.writeln('Cluster: ${cluster.id} - ${cluster.faces.length}');
    }
    debugPrint(sb.toString());
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'species': species,
        'assigned': assigned.map((e) => e.toJson()).toList(),
        'rejectedFaceIDs': rejectedFaceIDs,
        'avatarFaceID': avatarFaceID,
        'isHidden': isHidden,
        'isPinned': isPinned,
        'hideFromMemories': hideFromMemories,
        'birthDate': birthDate,
        'manuallyAssigned': manuallyAssigned,
      };

  factory PetData.fromJson(Map<String, dynamic> json) {
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
    final manualAssignmentData = json['manuallyAssigned'];
    final manuallyAssigned = manualAssignmentData is Iterable
        ? List<int>.from(
            manualAssignmentData.map<int?>((value) {
              if (value is num) return value.toInt();
              return int.tryParse(value.toString());
            }).whereType<int>(),
          )
        : <int>[];
    return PetData(
      name: json['name'] as String? ?? '',
      species: json['species'] as int? ?? -1,
      assigned: assigned,
      rejectedFaceIDs: rejectedFaceIDs,
      manuallyAssigned: manuallyAssigned,
      avatarFaceID: json['avatarFaceID'] as String?,
      isHidden: json['isHidden'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      hideFromMemories: json['hideFromMemories'] as bool? ?? false,
      birthDate: json['birthDate'] as String?,
    );
  }
}
