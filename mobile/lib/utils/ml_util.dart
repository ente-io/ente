import "dart:io" show File;

import "package:flutter/services.dart" show PlatformException;
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/services/machine_learning/ml_exceptions.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/thumbnail_util.dart";

final _logger = Logger("MlUtil");

enum FileDataForML { thumbnailData, fileData }

Future<List<int>> getIndexableFileIDs() async {
  return FilesDB.instance.getOwnedFileIDs(Configuration.instance.getUserID()!);
}

Future<String> getImagePathForML(
  EnteFile enteFile, {
  FileDataForML typeOfData = FileDataForML.fileData,
}) async {
  String? imagePath;

  switch (typeOfData) {
    case FileDataForML.fileData:
      final stopwatch = Stopwatch()..start();
      File? file;
      if (enteFile.fileType == FileType.video) {
        try {
          file = await getThumbnailForUploadedFile(enteFile);
        } on PlatformException catch (e, s) {
          _logger.severe(
            "Could not get thumbnail for $enteFile due to PlatformException",
            e,
            s,
          );
          throw ThumbnailRetrievalException(e.toString(), s);
        }
      } else {
        try {
          file = await getFile(enteFile, isOrigin: true);
        } catch (e, s) {
          _logger.severe(
            "Could not get file for $enteFile",
            e,
            s,
          );
        }
      }
      if (file == null) {
        _logger.warning(
          "Could not get file for $enteFile of type ${enteFile.fileType.toString()}",
        );
        break;
      }
      imagePath = file.path;
      stopwatch.stop();
      _logger.info(
        "Getting file data for uploadedFileID ${enteFile.uploadedFileID} took ${stopwatch.elapsedMilliseconds} ms",
      );
      break;

    case FileDataForML.thumbnailData:
      final stopwatch = Stopwatch()..start();
      final File? thumbnail = await getThumbnailForUploadedFile(enteFile);
      if (thumbnail == null) {
        _logger.warning("Could not get thumbnail for $enteFile");
        break;
      }
      imagePath = thumbnail.path;
      stopwatch.stop();
      _logger.info(
        "Getting thumbnail data for uploadedFileID ${enteFile.uploadedFileID} took ${stopwatch.elapsedMilliseconds} ms",
      );
      break;
  }

  if (imagePath == null) {
    _logger.warning(
      "Failed to get any data for enteFile with uploadedFileID ${enteFile.uploadedFileID} since its file path is null",
    );
    throw CouldNotRetrieveAnyFileData();
  }

  return imagePath;
}
