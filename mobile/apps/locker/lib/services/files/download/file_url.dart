import "package:locker/core/constants.dart";
import "package:locker/services/configuration.dart";

enum FileUrlType {
  download,
  publicDownload,
  thumbnail,
  publicThumbnail,
  directDownload,
}

class FileUrl {
  static String getUrl(int fileID, FileUrlType type) {
    final endpoint = Configuration.instance.getHttpEndpoint();
    final disableWorker = endpoint != kDefaultProductionEndpoint;

    switch (type) {
      case FileUrlType.directDownload:
        return "$endpoint/files/download/$fileID";
      case FileUrlType.download:
        return disableWorker
            ? "$endpoint/files/download/$fileID"
            : "https://files.ente.io/?fileID=$fileID";

      case FileUrlType.publicDownload:
        return disableWorker
            ? "$endpoint/public-collection/files/download/$fileID"
            : "https://public-albums.ente.io/download/?fileID=$fileID";

      case FileUrlType.thumbnail:
        return disableWorker
            ? "$endpoint/files/preview/$fileID"
            : "https://thumbnails.ente.io/?fileID=$fileID";

      case FileUrlType.publicThumbnail:
        return disableWorker
            ? "$endpoint/public-collection/files/preview/$fileID"
            : "https://public-albums.ente.io/preview/?fileID=$fileID";
    }
  }
}
