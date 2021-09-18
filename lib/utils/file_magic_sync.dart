import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/file_magic_metadata.dart';
import 'package:photos/services/remote_sync_service.dart';

import 'crypto_util.dart';
import 'file_download_util.dart';

class FileMagicService {
  Dio _dio;
  FilesDB _filesDB;

  FileMagicService._privateConstructor() {
    _filesDB = FilesDB.instance;
    _dio = Network.instance.getDio();
  }

  static final FileMagicService instance =
      FileMagicService._privateConstructor();

  Future<void> changeVisibility(List<File> files, int visibility) async {
    final params = <String, dynamic>{};
    params['metadataList'] = [];
    int ownerID = Configuration.instance.getUserID();
    for (final file in files) {
      if (file.uploadedFileID == null) {
        throw AssertionError("operation is only supported on backed up files");
      } else if (file.ownerID != ownerID) {
        throw AssertionError("can not modify memories not owned by you");
      }
      Map<String, dynamic> jsonToUpdate = jsonDecode(file.mMdEncodedJson);
      jsonToUpdate['visibility'] = visibility;

      // update the local information so that it's reflected on UI
      file.mMdEncodedJson = jsonEncode(jsonToUpdate);
      file.fileMagicMetadata = FileMagicMetadata.fromJson(jsonToUpdate);

      final fileKey = decryptFileKey(file);
      final encryptedMMd = await CryptoUtil.encryptChaCha(
          utf8.encode(jsonEncode(jsonToUpdate)), fileKey);
      params['metadataList'].add(UpdateMagicMetadata(
          id: file.uploadedFileID,
          magicMetadata: MagicMetadata(
            version: file.mMdVersion,
            count: jsonToUpdate.length,
            data: Sodium.bin2base64(encryptedMMd.encryptedData),
            header: Sodium.bin2base64(encryptedMMd.header),
          )));
    }
    return _dio
        .post(
      Configuration.instance.getHttpEndpoint() + "/files/update-magic-metadata",
      data: params,
      options:
          Options(headers: {"X-Auth-Token": Configuration.instance.getToken()}),
    )
        .then((value) async {
      // update the state of the selected file. Same file in other collection
      // should be eventually synced after remote sync has completed
      await _filesDB.insertMultiple(files);
      Bus.instance.fire(FilesUpdatedEvent(files));
      RemoteSyncService.instance.sync(silently: true);
    });
  }
}

class UpdateMagicMetadata {
  int id;
  MagicMetadata magicMetadata;

  UpdateMagicMetadata({this.id, this.magicMetadata});

  UpdateMagicMetadata.fromJson(dynamic json) {
    id = json['id'];
    magicMetadata = json['magicMetadata'] != null
        ? MagicMetadata.fromJson(json['magicMetadata'])
        : null;
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
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
