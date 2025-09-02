import 'package:dio/dio.dart';
import "package:flutter/material.dart";
import "package:latlong2/latlong.dart";
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network/network.dart';
import "package:photos/db/remote/table/files_table.dart";
import "package:photos/db/remote/table/mapping_table.dart";
import 'package:photos/extensions/list.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/backup_status.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/file_magic_service.dart';
import "package:photos/ui/components/action_sheet_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";

class FilesService {
  late Dio _enteDio;
  late Logger _logger;
  late Configuration _config;

  FilesService._privateConstructor() {
    _enteDio = NetworkClient.instance.enteDio;
    _logger = Logger("FilesService");
    _config = Configuration.instance;
  }

  static final FilesService instance = FilesService._privateConstructor();

  Future<int> getFileSize(int uploadedFileID) async {
    try {
      final response = await _enteDio.post(
        "/files/size",
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

  Future<bool> hasMigratedSizes() async {
    try {
      final List<int> uploadIDsWithMissingSize =
          await remoteDB.fileIDsWithMissingSize(_config.getUserID()!);
      if (uploadIDsWithMissingSize.isEmpty) {
        return Future.value(true);
      }
      await backFillSizes(uploadIDsWithMissingSize);
      return Future.value(true);
    } catch (e, s) {
      _logger.severe("error during has migrated sizes", e, s);
      return Future.value(false);
    }
  }

  Future<void> backFillSizes(List<int> uploadIDsWithMissingSize) async {
    final batchedFiles = uploadIDsWithMissingSize.chunks(1000);
    for (final batch in batchedFiles) {
      final Map<int, int> uploadIdToSize = await getFilesSizeFromInfo(batch);
      if (uploadIdToSize.isNotEmpty) {
        await remoteDB.updateSize(uploadIdToSize);
      }
    }
  }

  Future<BackupStatus> getBackupStatus({String? pathID}) async {
    final bool hasMigratedSize = await FilesService.instance.hasMigratedSizes();
    final Set<String>? localAssets =
        pathID == null ? null : await localDB.getAssetsIDsForPath(pathID);
    final BackedUpFileIDs ids = await remoteDB.getLocalIDsForUser(
      Configuration.instance.getUserID()!,
      localAssets,
    );
    late int size;
    if (hasMigratedSize) {
      size = ids.localSize;
    } else {
      size = await _getFileSize(ids.uploadedIDs);
    }
    return BackupStatus(ids.localIDs, size);
  }

  Future<int> _getFileSize(List<int> fileIDs) async {
    try {
      final response = await _enteDio.post(
        "/files/size",
        data: {"fileIDs": fileIDs},
      );
      return response.data["size"];
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
  }

  Future<Map<int, int>> getFilesSizeFromInfo(List<int> uploadedFileID) async {
    try {
      final response = await _enteDio.post(
        "/files/info",
        data: {"fileIDs": uploadedFileID},
      );
      final Map<int, int> idToSize = {};
      final List result = response.data["filesInfo"] as List;
      for (var fileInfo in result) {
        final int uploadedFileID = fileInfo["id"];
        final int size = fileInfo["fileInfo"]["fileSize"];
        idToSize[uploadedFileID] = size;
      }
      return idToSize;
    } catch (e, s) {
      _logger.severe("failed to fetch size from fileInfo", e, s);
      rethrow;
    }
  }

  Future<void> bulkEditLocationData(
    List<EnteFile> files,
    LatLng location,
    BuildContext context,
  ) async {
    final List<EnteFile> uploadedFiles =
        files.where((element) => element.rAsset != null).toList();

    final List<EnteFile> remoteFilesToUpdate = [];
    final Map<int, Map<String, dynamic>> fileIDToUpdateMetadata = {};
    await showActionSheet(
      context: context,
      body: AppLocalizations.of(context).changeLocationOfSelectedItems,
      buttons: [
        ButtonWidget(
          labelText: AppLocalizations.of(context).yes,
          buttonType: ButtonType.neutral,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          isInAlert: true,
          onTap: () async {
            await _editLocationData(
              uploadedFiles,
              fileIDToUpdateMetadata,
              remoteFilesToUpdate,
              location,
            );
          },
        ),
        ButtonWidget(
          labelText: AppLocalizations.of(context).cancel,
          buttonType: ButtonType.secondary,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.cancel,
          isInAlert: true,
        ),
      ],
    );
  }

  Future<void> _editLocationData(
    List<EnteFile> uploadedFiles,
    Map<int, Map<String, dynamic>> fileIDToUpdateMetadata,
    List<EnteFile> remoteFilesToUpdate,
    LatLng location,
  ) async {
    for (EnteFile remoteFile in uploadedFiles) {
      // discard files not owned by user and also dedupe already processed
      // files
      if (remoteFile.ownerID != _config.getUserID()! ||
          fileIDToUpdateMetadata.containsKey(remoteFile.uploadedFileID!)) {
        continue;
      }

      remoteFilesToUpdate.add(remoteFile);
      fileIDToUpdateMetadata[remoteFile.uploadedFileID!] = {
        latKey: location.latitude,
        longKey: location.longitude,
      };
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
