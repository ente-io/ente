import 'package:dio/dio.dart';
import 'package:photos/core/configuration.dart';

class AlbumSharingService {
  final _dio = Dio();

  AlbumSharingService._privateConstructor();
  static final AlbumSharingService instance =
      AlbumSharingService._privateConstructor();

  Future<Map<String, bool>> getSharingStatus(String path) async {
    // TODO fetch folderID from path
    var folderID = 0;
    return _dio
        .get(
      Configuration.instance.getHttpEndpoint() + "/users",
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((usersResponse) {
      return _dio
          .get(
        Configuration.instance.getHttpEndpoint() +
            "/folders/" +
            folderID.toString(),
        options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      )
          .then((sharedFoldersResponse) {
        final sharedUsers =
            (sharedFoldersResponse.data["sharedWith"] as List).toSet();
        final result = Map<String, bool>();
        (usersResponse.data as List).forEach((user) {
          if (user != Configuration.instance.getUsername()) {
            result[user] = sharedUsers.contains(user);
          }
        });
        return result;
      });
    });
  }

  void shareAlbum(
    String path,
  ) {}
}
