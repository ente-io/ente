// ignore: import_of_legacy_library_into_null_safe
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';

class FilesService {
  late Configuration _config;
  late Dio _dio;
  late Logger _logger;
  FilesService._privateConstructor() {
    _config = Configuration.instance;
    _dio = Network.instance.getDio();
    _logger = Logger("FilesService");
  }
  static final FilesService instance = FilesService._privateConstructor();

  Future<int> getFileSize(int uploadedFileID) async {
    try {
      final response = await _dio.post(
        Configuration.instance.getHttpEndpoint() + "/files/size",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
        data: {
          "fileIDs": [uploadedFileID],
        },
      );
      return response.data["size"];
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
  }
}
