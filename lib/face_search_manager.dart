import 'package:dio/dio.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/files_db.dart';
import 'package:logging/logging.dart';

import 'package:photos/models/face.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/file_name_util.dart';

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

  Future<List<File>> getFaceSearchResults(
      Face face, int beforeCreationTime, int limit) async {
    _logger.info("Fetching since creation " + beforeCreationTime.toString());
    final result = await _dio
        .get(
      Configuration.instance.getHttpEndpoint() +
          "/search/face/" +
          face.faceID.toString(),
      queryParameters: {
        "limit": limit,
        "beforeCreationTime": beforeCreationTime,
      },
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((response) {
      return (response.data["result"] as List)
          .map((p) => File.fromJson(p))
          .toList();
    }).catchError(_onError);
    final files = List<File>();
    if (result == null) {
      return throw ("Oops. Could not fetch search results.");
    }
    for (File file in result) {
      try {
        files.add(await FilesDB.instance.getMatchingFile(
            file.localId,
            file.title,
            file.deviceFolder,
            file.creationTime,
            file.modificationTime,
            alternateTitle: getHEICFileNameForJPG(file)));
      } catch (e) {
        // Not available locally
        files.add(file);
      }
    }
    files.sort((first, second) {
      return second.creationTime.compareTo(first.creationTime);
    });
    return files;
  }

  void _onError(error) {
    _logger.severe(error);
  }
}
