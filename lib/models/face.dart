import 'package:photos/core/configuration.dart';

class Face {
  final int faceID;

  Face.fromJson(Map<String, dynamic> json) : faceID = json["faceID"];

  String getThumbnailUrl() {
    return Configuration.instance.getHttpEndpoint() +
        "/photos/face/thumbnail/" +
        faceID.toString() +
        "?token=" +
        Configuration.instance.getToken();
  }
}
