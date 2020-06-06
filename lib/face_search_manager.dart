import 'package:dio/dio.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/photo_db.dart';
import 'package:logging/logging.dart';

import 'package:photos/models/face.dart';
import 'package:photos/models/photo.dart';

class FaceSearchManager {
  final _logger = Logger("FaceSearchManager");
  final _dio = Dio();

  FaceSearchManager._privateConstructor();
  static final FaceSearchManager instance =
      FaceSearchManager._privateConstructor();

  Future<List<Face>> getFaces() {
    return _dio
        .get(
          Configuration.instance.getHttpEndpoint() + "/photos/faces",
          options: Options(
              headers: {"X-Auth-Token": Configuration.instance.getToken()}),
        )
        .then((response) => (response.data["faces"] as List)
            .map((face) => new Face.fromJson(face))
            .toList())
        .catchError(_onError);
  }

  Future<List<Photo>> getFaceSearchResults(Face face) async {
    final result = await _dio
        .get(
      Configuration.instance.getHttpEndpoint() +
          "/photos/search/face/" +
          face.faceID.toString(),
      queryParameters: {
        "limit": 200,
      },
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((response) {
      return (response.data["result"] as List)
          .map((p) => Photo.fromJson(p))
          .toList();
    }).catchError(_onError);
    final photos = List<Photo>();
    for (Photo photo in result) {
      try {
        photos.add(await PhotoDB.instance.getMatchingPhoto(photo.localId,
            photo.title, photo.deviceFolder, photo.createTimestamp));
      } catch (e) {
        // Not available locally
        photos.add(photo);
      }
    }
    photos.sort((first, second) {
      return second.createTimestamp.compareTo(first.createTimestamp);
    });
    return photos;
  }

  void _onError(error) {
    _logger.severe(error);
  }
}
