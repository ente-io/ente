import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ente_crypto/ente_crypto.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/extensions/list.dart';
import "package:photos/models/api/metadata.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/models/metadata/file_magic.dart";
import 'package:photos/services/sync/remote_sync_service.dart';
import "package:photos/utils/file_key.dart";

class FileMagicService {
  final _logger = Logger("FileMagicService");
  late Dio _enteDio;
  late FilesDB _filesDB;

  FileMagicService._privateConstructor() {
    _filesDB = FilesDB.instance;
    _enteDio = NetworkClient.instance.enteDio;
  }

  static final FileMagicService instance =
      FileMagicService._privateConstructor();

  Future<void> changeVisibility(List<EnteFile> files, int visibility) async {
    final Map<String, dynamic> update = {magicKeyVisibility: visibility};
    await _updateMagicData(files, update);
    if (visibility == visibleVisibility) {
      // Force reload home gallery to pull in the now unarchived files
      Bus.instance.fire(ForceReloadHomeGalleryEvent("unarchivedFiles"));
      Bus.instance.fire(
        LocalPhotosUpdatedEvent(
          files,
          type: EventType.unarchived,
          source: "vizChange",
        ),
      );
    } else {
      Bus.instance.fire(
        LocalPhotosUpdatedEvent(
          files,
          type: EventType.archived,
          source: "vizChange",
        ),
      );
    }
  }

  Future<void> updatePublicMagicMetadata(
    List<EnteFile> files,
    Map<String, dynamic>? newMetadataUpdate, {
    Map<int, Map<String, dynamic>>? metadataUpdateMap,
  }) async {
    final params = <String, dynamic>{};
    params['metadataList'] = [];
    final int ownerID = Configuration.instance.getUserID()!;
    try {
      for (final file in files) {
        if (file.uploadedFileID == null) {
          throw AssertionError(
            "operation is only supported on backed up files",
          );
        } else if (file.ownerID != ownerID) {
          throw AssertionError("cannot modify memories not owned by you");
        }
        // read the existing magic metadata and apply new updates to existing data
        // current update is simple replace. This will be enhanced in the future,
        // as required.
        final newUpdates = metadataUpdateMap != null
            ? metadataUpdateMap[file.uploadedFileID]
            : newMetadataUpdate;
        assert(
          newUpdates != null && newUpdates.isNotEmpty,
          "can not apply empty updates",
        );
        final Map<String, dynamic> jsonToUpdate =
            jsonDecode(file.pubMmdEncodedJson ?? '{}');
        newUpdates!.forEach((key, value) {
          jsonToUpdate[key] = value;
        });

        // update the local information so that it's reflected on UI
        file.pubMmdEncodedJson = jsonEncode(jsonToUpdate);
        file.pubMagicMetadata = PubMagicMetadata.fromJson(jsonToUpdate);

        final fileKey = getFileKey(file);
        final encryptedMMd = await CryptoUtil.encryptChaCha(
          utf8.encode(jsonEncode(jsonToUpdate)),
          fileKey,
        );
        params['metadataList'].add(
          UpdateMagicMetadataRequest(
            id: file.uploadedFileID!,
            magicMetadata: MetadataRequest(
              version: file.pubMmdVersion,
              count: jsonToUpdate.length,
              data: CryptoUtil.bin2base64(encryptedMMd.encryptedData!),
              header: CryptoUtil.bin2base64(encryptedMMd.header!),
            ),
          ),
        );
        file.pubMmdVersion = file.pubMmdVersion + 1;
      }

      await _enteDio.put("/files/public-magic-metadata", data: params);
      // update the state of the selected file. Same file in other collection
      // should be eventually synced after remote sync has completed
      await _filesDB.insertMultiple(files);
      RemoteSyncService.instance.sync(silently: true).ignore();
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 409) {
        RemoteSyncService.instance.sync(silently: true).ignore();
      }
      rethrow;
    } catch (e, s) {
      _logger.severe("failed to sync magic metadata", e, s);
      rethrow;
    }
  }

  Future<void> _updateMagicData(
    List<EnteFile> files,
    Map<String, dynamic> newMetadataUpdate,
  ) async {
    final params = <String, dynamic>{};
    final int ownerID = Configuration.instance.getUserID()!;
    final batchedFiles = files.chunks(batchSize);
    try {
      for (final batch in batchedFiles) {
        params['metadataList'] = [];
        for (final file in batch) {
          if (file.uploadedFileID == null) {
            throw AssertionError(
              "operation is only supported on backed up files",
            );
          } else if (file.ownerID != ownerID) {
            throw AssertionError("cannot modify memories not owned by you");
          }
          // read the existing magic metadata and apply new updates to existing data
          // current update is simple replace. This will be enhanced in the future,
          // as required.
          final Map<String, dynamic> jsonToUpdate =
              jsonDecode(file.mMdEncodedJson ?? '{}');
          newMetadataUpdate.forEach((key, value) {
            jsonToUpdate[key] = value;
          });

          // update the local information so that it's reflected on UI
          file.mMdEncodedJson = jsonEncode(jsonToUpdate);
          file.magicMetadata = MagicMetadata.fromJson(jsonToUpdate);

          final fileKey = getFileKey(file);
          final encryptedMMd = await CryptoUtil.encryptChaCha(
            utf8.encode(jsonEncode(jsonToUpdate)),
            fileKey,
          );
          params['metadataList'].add(
            UpdateMagicMetadataRequest(
              id: file.uploadedFileID!,
              magicMetadata: MetadataRequest(
                version: file.mMdVersion,
                count: jsonToUpdate.length,
                data: CryptoUtil.bin2base64(encryptedMMd.encryptedData!),
                header: CryptoUtil.bin2base64(encryptedMMd.header!),
              ),
            ),
          );
          file.mMdVersion = file.mMdVersion + 1;
        }

        await _enteDio.put("/files/magic-metadata", data: params);
        await _filesDB.insertMultiple(files);
      }

      // update the state of the selected file. Same file in other collection
      // should be eventually synced after remote sync has completed
      RemoteSyncService.instance.sync(silently: true).ignore();
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 409) {
        RemoteSyncService.instance.sync(silently: true).ignore();
      }
      rethrow;
    } catch (e, s) {
      _logger.severe("failed to sync magic metadata", e, s);
      rethrow;
    }
  }
}
