// import "dart:io";

import "package:dio/dio.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/network/network.dart";
import "package:photos/face/model/face.dart";

final _logger = Logger("import_from_zip");
Future<List<Face>> downloadZip() async {
  final List<Face> result = [];
  for (int i = 0; i < 2; i++) {
    _logger.info("downloading $i");
    final remoteZipUrl = "http://192.168.1.13:8700/ml/cx_ml_json_${i}.json";
    final response = await NetworkClient.instance.getDio().get(
          remoteZipUrl,
          options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()},
          ),
        );

    if (response.statusCode != 200) {
      _logger.warning('download failed ${response.toString()}');
      throw Exception("download failed");
    }
    final res = response.data as List<dynamic>;
    for (final item in res) {
      try {
        result.add(Face.fromJson(item));
      } catch (e) {
        _logger.warning("failed to parse $item");
        rethrow;
      }
    }
  }
  Set<String> faceID = {};
  for (final face in result) {
    if (faceID.contains(face.faceID)) {
      _logger.warning("duplicate faceID ${face.faceID}");
    }
    faceID.add(face.faceID);
  }
  return result;
}
