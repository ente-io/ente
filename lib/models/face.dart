import 'package:photos/core/configuration.dart';

class Face {
  final int id;

  Face.fromJson(Map<String, dynamic> json) : id = json["id"];

  String getThumbnailUrl() {
    return Configuration.instance.getHttpEndpoint() +
        "/photos/face/thumbnail/" +
        id.toString() +
        "?token=" +
        Configuration.instance.getToken();
  }
}
