import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_download_util.dart';

class FileMagicService {
  final _logger = Logger("FileMagicService");
  Dio _dio;
  FilesDB _filesDB;

  FileMagicService._privateConstructor() {
    _filesDB = FilesDB.instance;
    _dio = Network.instance.getDio();
  }

  static final FileMagicService instance =
      FileMagicService._privateConstructor();

  Future<void> changeVisibility(List<File> files, int visibility) async {
    Map<String, dynamic> update = {};
    update[kMagicKeyVisibility] = visibility;
    return _updateMagicData(files, update);
  }

  Future<void> _updateMagicData(
      List<File> files, Map<String, dynamic> newMetadataUpdate) async {
    final params = <String, dynamic>{};
    params['metadataList'] = [];
    final int ownerID = Configuration.instance.getUserID();
    try {
      for (final file in files) {
        if (file.uploadedFileID == null) {
          throw AssertionError(
              "operation is only supported on backed up files");
        } else if (file.ownerID != ownerID) {
          throw AssertionError("cannot modify memories not owned by you");
        }
        // read the existing magic metadata and apply new updates to existing data
        // current update is simple replace. This will be enhanced in the future,
        // as required.
        Map<String, dynamic> jsonToUpdate = jsonDecode(file.mMdEncodedJson);
        newMetadataUpdate.forEach((key, value) {
          jsonToUpdate[key] = value;
        });

        // update the local information so that it's reflected on UI
        file.mMdEncodedJson = jsonEncode(jsonToUpdate);
        file.magicMetadata = MagicMetadata.fromJson(jsonToUpdate);

        final fileKey = decryptFileKey(file);
        final encryptedMMd = await CryptoUtil.encryptChaCha(
            utf8.encode(jsonEncode(jsonToUpdate)), fileKey);
        params['metadataList'].add(UpdateMagicMetadataRequest(
            id: file.uploadedFileID,
            magicMetadata: MagicMetadata(
              version: file.mMdVersion,
              count: jsonToUpdate.length,
              data: Sodium.bin2base64(encryptedMMd.encryptedData),
              header: Sodium.bin2base64(encryptedMMd.header),
            )));
      }

      await _dio.put(
        Configuration.instance.getHttpEndpoint() +
            "/files/magic-metadata",
        data: params,
        options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()}),
      );
      // update the state of the selected file. Same file in other collection
      // should be eventually synced after remote sync has completed
      await _filesDB.insertMultiple(files);
      Bus.instance.fire(FilesUpdatedEvent(files));
      RemoteSyncService.instance.sync(silently: true);
    } on DioError catch (e) {
      if (e.response != null && e.response.statusCode == 409) {
        RemoteSyncService.instance.sync(silently: true);
      }
      rethrow;
    } catch (e, s) {
      _logger.severe("failed to sync magic metadata", e, s);
      rethrow;
    }
  }
}

class UpdateMagicMetadataRequest {
  final int id;
  final MagicMetadata magicMetadata;

  UpdateMagicMetadataRequest({this.id, this.magicMetadata});

  factory UpdateMagicMetadataRequest.fromJson(dynamic json) {
    return UpdateMagicMetadataRequest(
        id: json['id'],
        magicMetadata: json['magicMetadata'] != null
            ? MagicMetadata.fromJson(json['magicMetadata'])
            : null);
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    if (magicMetadata != null) {
      map['magicMetadata'] = magicMetadata.toJson();
    }
    return map;
  }
}

class MagicMetadata {
  int version;
  int count;
  String data;
  String header;

  MagicMetadata({this.version, this.count, this.data, this.header});

  MagicMetadata.fromJson(dynamic json) {
    version = json['version'];
    count = json['count'];
    data = json['data'];
    header = json['header'];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map['version'] = version;
    map['count'] = count;
    map['data'] = data;
    map['header'] = header;
    return map;
  }
}
