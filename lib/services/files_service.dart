import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/extensions/list.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/services/file_magic_service.dart';
import 'package:photos/utils/date_time_util.dart';

class FilesService {
  late Dio _enteDio;
  late Logger _logger;
  late FilesDB _filesDB;
  late Configuration _config;

  FilesService._privateConstructor() {
    _enteDio = Network.instance.enteDio;
    _logger = Logger("FilesService");
    _filesDB = FilesDB.instance;
    _config = Configuration.instance;
  }

  static final FilesService instance = FilesService._privateConstructor();

  Future<int> getFileSize(int uploadedFileID) async {
    try {
      final response = await _enteDio.post(
        "/files/size",
        data: {
          "fileIDs": [uploadedFileID]
        },
      );
      return response.data["size"];
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
  }

  Future<void> bulkEditTime(
    List<File> files,
    EditTimeSource source,
  ) async {
    assert(
      source == EditTimeSource.fileName,
      "edit source ${source.name} is not supported yet",
    );
    final ListMatch<File> result = files.splitMatch(
      (element) => element.isUploaded,
    );
    final List<File> uploadedFiles = result.matched;
    // editTime For LocalFiles
    final List<File> localOnlyFiles = result.unmatched;
    for (File localFile in localOnlyFiles) {
      final timeResult = parseDateTimeFromFileNameV2(
        basenameWithoutExtension(localFile.title ?? ""),
      );
      if (timeResult != null) {
        localFile.creationTime = timeResult.microsecondsSinceEpoch;
      }
    }
    await _filesDB.insertMultiple(localOnlyFiles);

    final List<File> remoteFilesToUpdate = [];
    final Map<int, Map<String, int>> fileIDToUpdateMetadata = {};
    for (File remoteFile in uploadedFiles) {
      // discard files not owned by user and also dedupe already processed
      // files
      if (remoteFile.ownerID != _config.getUserID()! ||
          fileIDToUpdateMetadata.containsKey(remoteFile.uploadedFileID)) {
        continue;
      }
      final timeResult = parseDateTimeFromFileNameV2(
        basenameWithoutExtension(remoteFile.title ?? ""),
      );
      if (timeResult != null) {
        remoteFilesToUpdate.add(remoteFile);
        fileIDToUpdateMetadata[remoteFile.uploadedFileID!] = {
          pubMagicKeyEditedTime: timeResult.microsecondsSinceEpoch,
        };
      }
    }
    if (remoteFilesToUpdate.isNotEmpty) {
      await FileMagicService.instance.updatePublicMagicMetadata(
        remoteFilesToUpdate,
        null,
        metadataUpdateMap: fileIDToUpdateMetadata,
      );
    }
  }
}

enum EditTimeSource {
  // parse the time from fileName
  fileName,
  // parse the time from exif data of file.
  exif,
  // use the which user provided as input
  manualFix,
  // adjust the time of selected photos by +/- time.
  // required for cases when the original device in which photos were taken
  // had incorrect time (quite common with physical cameras)
  manualAdjusted,
}
