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
import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/api/metadata.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/sync/remote_sync_service.dart';
import "package:photos/utils/file_key.dart";

class FileMagicService {
  final _logger = Logger("FileMagicService");
  late Dio _enteDio;

  FileMagicService._privateConstructor() {
    _filesDB = FilesDB.instance;
    _enteDio = NetworkClient.instance.enteDio;
  }

  static final FileMagicService instance =
      FileMagicService._privateConstructor();

  Future<void> changeVisibility(List<EnteFile> files, int visibility) async {
    final Map<String, dynamic> update = {magicKeyVisibility: visibility};
    await _updatePrivateMagicData(files, update);
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
      final Map<int, RemoteAsset> updatedRAssets = {};
      for (final file in files) {
        if (file.rAsset == null) {
          throw AssertionError(
            "operation is only supported on backed up files",
          );
        }
        final rAsset = file.rAsset!;
        if (rAsset.ownerID != ownerID) {
          throw AssertionError("cannot modify memories not owned by you");
        }
        // read the existing magic metadata and apply new updates to existing data
        // current update is simple replace. This will be enhanced in the future,
        // as required.
        final newUpdates = metadataUpdateMap != null
            ? metadataUpdateMap[rAsset.id]
            : newMetadataUpdate;
        assert(
          newUpdates != null && newUpdates.isNotEmpty,
          "can not apply empty updates",
        );

        final Map<String, dynamic> jsonToUpdate =
            rAsset.publicMetadata?.data ?? {};
        final currentVersion = rAsset.publicMetadata?.version ?? 0;
        newUpdates!.forEach((key, value) {
          jsonToUpdate[key] = value;
        });
        final fileKey = getFileKey(file);
        final encryptedMMd = await CryptoUtil.encryptChaCha(
          utf8.encode(jsonEncode(jsonToUpdate)),
          fileKey,
        );
        params['metadataList'].add(
          UpdateMagicMetadataRequest(
            id: file.uploadedFileID!,
            magicMetadata: MetadataRequest(
              version: currentVersion,
              count: jsonToUpdate.length,
              data: CryptoUtil.bin2base64(encryptedMMd.encryptedData!),
              header: CryptoUtil.bin2base64(encryptedMMd.header!),
            ),
          ),
        );
        updatedRAssets[rAsset.id] = rAsset.copyWith(
          publicMetadata: Metadata(
            data: jsonToUpdate,
            version: currentVersion + 1,
          ),
        );
      }
      await _enteDio.put("/files/public-magic-metadata", data: params);
      // update the state of the selected file. Same file in other collection
      // should be eventually synced after remote sync has completed
      for (final file in files) {
        file.rAsset = updatedRAssets[file.rAsset!.id]!;
      }
      remoteCache.updateItems(updatedRAssets.values.toList());
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

  Future<void> _updatePrivateMagicData(
    List<EnteFile> files,
    Map<String, dynamic> newMetadataUpdate,
  ) async {
    final int ownerID = Configuration.instance.getUserID()!;
    final batchedFiles = files.chunks(batchSize);
    try {
      for (final batch in batchedFiles) {
        final Map<int, RemoteAsset> updatedRAssets = {};
        final params = <String, dynamic>{};
        params['metadataList'] = [];
        for (final file in batch) {
          if (file.rAsset == null) {
            throw AssertionError(
              "operation is only supported on backed up files",
            );
          }
          final rAsset = file.rAsset!;
          if (rAsset.ownerID != ownerID) {
            throw AssertionError("cannot modify memories not owned by you");
          }
          // read the existing magic metadata and apply new updates to existing data
          // current update is simple replace. This will be enhanced in the future,
          // as required.
          final Map<String, dynamic> jsonToUpdate =
              rAsset.privateMetadata?.data ?? {};
          final currentVersion = rAsset.privateMetadata?.version ?? 0;
          newMetadataUpdate.forEach((key, value) {
            jsonToUpdate[key] = value;
          });

          final fileKey = getFileKey(file);
          final encryptedMMd = await CryptoUtil.encryptChaCha(
            utf8.encode(jsonEncode(jsonToUpdate)),
            fileKey,
          );
          params['metadataList'].add(
            UpdateMagicMetadataRequest(
              id: file.uploadedFileID!,
              magicMetadata: MetadataRequest(
                version: currentVersion,
                count: jsonToUpdate.length,
                data: CryptoUtil.bin2base64(encryptedMMd.encryptedData!),
                header: CryptoUtil.bin2base64(encryptedMMd.header!),
              ),
            ),
          );
          // for updating the local information so that it's reflected on UI
          updatedRAssets[rAsset.id] = rAsset.copyWith(
            privateMetadata: Metadata(
              data: jsonToUpdate,
              version: currentVersion + 1,
            ),
          );
        }
        await _enteDio.put("/files/magic-metadata", data: params);
        for (final file in batch) {
          file.rAsset = updatedRAssets[file.rAsset!.id]!;
        }
        remoteCache.updateItems(updatedRAssets.values.toList());
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
