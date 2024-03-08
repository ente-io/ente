import 'package:photos/face/model/face.dart';

class PersonFace {
  final Face face;
  int? personID;
  bool? confirmed;
  double? closeDist;
  String? closeFaceID;

  PersonFace(
    this.face,
    this.personID,
    this.closeDist,
    this.closeFaceID, {
    this.confirmed,
  });

  // toJson
  Map<String, dynamic> toJson() => {
        'face': face.toJson(),
        'personID': personID,
        'confirmed': confirmed ?? false,
        'close_dist': closeDist,
        'close_face_id': closeFaceID,
      };

  // fromJson
  factory PersonFace.fromJson(Map<String, dynamic> json) {
    return PersonFace(
      Face.fromJson(json['face'] as Map<String, dynamic>),
      json['personID'] as int?,
      json['close_dist'] as double?,
      json['close_face_id'] as String?,
      confirmed: json['confirmed'] as bool?,
    );
  }
}
