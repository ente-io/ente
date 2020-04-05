import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:myapp/core/constants.dart' as Constants;

import 'models/face.dart';

class FaceSearchManager {
  final _logger = Logger();
  final _dio = Dio();

  Future<List<Face>> getFaces() {
    return _dio
        .get(Constants.ENDPOINT + "/faces",
            queryParameters: {"user": Constants.USER})
        .then((response) => (response.data["faces"] as List)
            .map((face) => new Face.fromJson(face))
            .toList())
        .catchError(_onError);
  }

  void _onError(error) {
    _logger.e(error);
  }
}
