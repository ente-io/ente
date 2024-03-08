class Person {
  final String remoteID;
  final PersonAttr attr;
  Person(
    this.remoteID,
    this.attr,
  );

  // copyWith
  Person copyWith({
    String? remoteID,
    PersonAttr? attr,
  }) {
    return Person(
      remoteID ?? this.remoteID,
      attr ?? this.attr,
    );
  }
}

class PersonAttr {
  final String name;
  final bool isHidden;
  String? avatarFaceId;
  final List<String> faces;
  final String? birthDatae;
  PersonAttr({
    required this.name,
    required this.faces,
    this.avatarFaceId,
    this.isHidden = false,
    this.birthDatae,
  });
  // copyWith
  PersonAttr copyWith({
    String? name,
    List<String>? faces,
    String? avatarFaceId,
    bool? isHidden,
    String? birthDatae,
  }) {
    return PersonAttr(
      name: name ?? this.name,
      faces: faces ?? this.faces,
      avatarFaceId: avatarFaceId ?? this.avatarFaceId,
      isHidden: isHidden ?? this.isHidden,
      birthDatae: birthDatae ?? this.birthDatae,
    );
  }

  // toJson
  Map<String, dynamic> toJson() => {
        'name': name,
        'faces': faces.toList(),
        'avatarFaceId': avatarFaceId,
        'isHidden': isHidden,
        'birthDatae': birthDatae,
      };

  // fromJson
  factory PersonAttr.fromJson(Map<String, dynamic> json) {
    return PersonAttr(
      name: json['name'] as String,
      faces: List<String>.from(json['faces'] as List<dynamic>),
      avatarFaceId: json['avatarFaceId'] as String?,
      isHidden: json['isHidden'] as bool? ?? false,
      birthDatae: json['birthDatae'] as String?,
    );
  }
}
