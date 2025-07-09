import "package:photos/db/local/table/device_albums.dart";
import "package:photos/models/device_collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/local/import/local_import.dart";

extension DeviceAlbums on LocalImportService {
  Future<List<DeviceCollection>> getDeviceCollections() async {
    return localDB.getDeviceCollections();
  }

  Future<List<EnteFile>> getAlbumFiles(String pathID) async {
    return localDB.getPathAssets(pathID);
  }
}
