import 'package:dio/dio.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';
import 'package:photos/models/trash_item_request.dart';

class TrashSyncService {
  TrashSyncService._privateConstructor();

  static final TrashSyncService instance =
      TrashSyncService._privateConstructor();
  final _dio = Network.instance.getDio();

  Future<void> trashFilesOnServer(List<TrashRequest> trashRequestItems) async {
    final params = <String, dynamic>{};
    params["items"] = [];
    for (final item in trashRequestItems) {
      params["items"].add(item.toJson());
    }
    return await _dio.post(
      Configuration.instance.getHttpEndpoint() + "/files/trash",
      options: Options(
        headers: {
          "X-Auth-Token": Configuration.instance.getToken(),
        },
      ),
      data: params,
    );
  }
}
