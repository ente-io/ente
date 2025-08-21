import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:ente_network/network.dart';
import 'package:locker/core/errors.dart';
import "package:locker/services/collections/collections_service.dart";
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/collections/models/collection_file_item.dart';
import 'package:locker/services/collections/models/collection_magic.dart';
import 'package:locker/services/collections/models/diff.dart';
import 'package:locker/services/configuration.dart';
import "package:locker/services/files/sync/metadata_updater_service.dart";
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/files/sync/models/file_magic.dart';
import 'package:locker/services/trash/models/trash_item_request.dart';
import "package:locker/utils/crypto_helper.dart";
import 'package:logging/logging.dart';

class CollectionApiClient {
  CollectionApiClient._privateConstructor();

  static final CollectionApiClient instance =
      CollectionApiClient._privateConstructor();

  final _logger = Logger("CollectionApiClient");
  final _enteDio = Network.instance.enteDio;
  final _config = Configuration.instance;

  Future<void> init() async {}

  Future<List<Collection>> getCollections(int sinceTime) async {
    try {
      final response = await _enteDio.get(
        "/collections/v2",
        queryParameters: {
          "sinceTime": sinceTime,
        },
      );
      final List<Collection> collections = [];
      final c = response.data["collections"];
      for (final collectionData in c) {
        final Collection collection =
            await _fromRemoteCollection(collectionData);
        collections.add(collection);
      }
      return collections;
    } catch (e, s) {
      _logger.warning(e, s);
      if (e is DioException && e.response?.statusCode == 401) {
        throw UnauthorizedError();
      }
      rethrow;
    }
  }

  Future<Diff> getFiles(Collection collection, int sinceTime) async {
    _logger.info(
      "[Collection-${collection.id}] fetch diff since: $sinceTime",
    );
    bool hasMore = true;
    final List<EnteFile> updatedFiles = [];
    final List<EnteFile> deletedFiles = [];
    int latestUpdatedAtTime = 0;
    final collectionKey = CryptoHelper.instance.getCollectionKey(collection);
    while (hasMore) {
      final diff = await _getDiff(collection.id, collectionKey, sinceTime);
      updatedFiles.addAll(diff.updatedFiles);
      deletedFiles.addAll(diff.deletedFiles);
      latestUpdatedAtTime = max(latestUpdatedAtTime, diff.latestUpdatedAtTime);
      hasMore = diff.hasMore;
    }
    final finalDiff = Diff(
      updatedFiles,
      deletedFiles,
      false,
      latestUpdatedAtTime,
    );
    _logger.info("[Collection-${collection.id}] fetched");
    return finalDiff;
  }

  Future<void> addToCollection(
    Collection collection,
    List<EnteFile> files,
  ) async {
    final pendingUpload = files.any(
      (element) => element.uploadedFileID == null,
    );
    if (pendingUpload) {
      throw ArgumentError('Can only add uploaded files');
    }
    if (files.isEmpty) {
      _logger.info("nothing to add to the collection");
      return;
    }
    final params = <String, dynamic>{};
    params["collectionID"] = collection.id;
    final collectionKey = CryptoHelper.instance.getCollectionKey(collection);
    params["files"] = [];
    for (final file in files) {
      final int uploadedFileID = file.uploadedFileID!;
      final fileKey = await CollectionService.instance.getFileKey(file);
      final encryptedKeyData = CryptoUtil.encryptSync(fileKey, collectionKey);
      final String encryptedKey =
          CryptoUtil.bin2base64(encryptedKeyData.encryptedData!);
      final String keyDecryptionNonce =
          CryptoUtil.bin2base64(encryptedKeyData.nonce!);
      params["files"].add(
        CollectionFileItem(uploadedFileID, encryptedKey, keyDecryptionNonce)
            .toMap(),
      );
    }
    try {
      await _enteDio.post(
        "/collections/add-files",
        data: params,
      );
    } catch (e) {
      _logger.warning('failed to add files to collection', e);
      rethrow;
    }
  }

  Future<void> trash(List<TrashRequest> requests) async {
    final requestData = <String, dynamic>{};
    requestData["items"] = [];
    for (final request in requests) {
      requestData["items"].add(request.toJson());
    }
    final response = await _enteDio.post(
      "/files/trash",
      data: requestData,
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to remove files from collection");
    }
  }

  Future<void> rename(Collection collection, String newName) async {
    final collectionKey = CryptoHelper.instance.getCollectionKey(collection);
    final encryptedName = CryptoUtil.encryptSync(
      utf8.encode(newName),
      collectionKey,
    );
    final params = <String, dynamic>{};
    params["collectionID"] = collection.id;
    params["encryptedName"] =
        CryptoUtil.bin2base64(encryptedName.encryptedData!);
    params["nameDecryptionNonce"] = CryptoUtil.bin2base64(encryptedName.nonce!);
    try {
      await _enteDio.post(
        "/collections/rename",
        data: params,
      );
    } catch (e) {
      _logger.warning("failed to rename collection", e);
      rethrow;
    }
  }

  Future<void> move(
    EnteFile file,
    Collection fromCollection,
    Collection toCollection,
  ) async {
    final params = <String, dynamic>{};
    params["fromCollectionID"] = fromCollection.id;
    params["toCollectionID"] = toCollection.id;
    final fileKey = await CollectionService.instance.getFileKey(file);
    final encryptedKeyData = CryptoUtil.encryptSync(
      fileKey,
      CryptoHelper.instance.getCollectionKey(toCollection),
    );
    params["files"] = [];
    params["files"].add(
      CollectionFileItem(
        file.uploadedFileID!,
        CryptoUtil.bin2base64(encryptedKeyData.encryptedData!),
        CryptoUtil.bin2base64(encryptedKeyData.nonce!),
      ).toMap(),
    );
    await _enteDio.post(
      "/collections/move-files",
      data: params,
    );
  }

  Future<void> trashCollection(Collection collection) async {
    try {
      await _enteDio.delete(
        "/collections/v3/${collection.id}?keepFiles=False&collectionID=${collection.id}",
      );
    } catch (e) {
      _logger.severe('failed to trash collection', e);
      rethrow;
    }
  }

  Future<Diff> _getDiff(
    int collectionID,
    Uint8List collectionKey,
    int sinceTime,
  ) async {
    try {
      final response = await _enteDio.get(
        "/collections/v2/diff",
        queryParameters: {
          "collectionID": collectionID,
          "sinceTime": sinceTime,
        },
      );
      int latestUpdatedAtTime = 0;
      final diff = response.data["diff"] as List;
      final bool hasMore = response.data["hasMore"] as bool;
      final startTime = DateTime.now();
      final deletedFiles = <EnteFile>[];
      final updatedFiles = <EnteFile>[];

      for (final item in diff) {
        final file = EnteFile();
        file.uploadedFileID = item["id"];
        file.collectionID = item["collectionID"];
        file.updationTime = item["updationTime"];
        latestUpdatedAtTime = max(latestUpdatedAtTime, file.updationTime!);
        if (item["isDeleted"]) {
          deletedFiles.add(file);
          continue;
        }
        file.ownerID = item["ownerID"];
        file.fileDecryptionHeader = item["file"]["decryptionHeader"];
        file.thumbnailDecryptionHeader = item["thumbnail"]["decryptionHeader"];
        file.metadataDecryptionHeader = item["metadata"]["decryptionHeader"];
        if (item["info"] != null) {
          file.fileSize = item["info"]["fileSize"];
        }
        file.encryptedKey = item["encryptedKey"];
        file.keyDecryptionNonce = item["keyDecryptionNonce"];
        final fileKey = CryptoHelper.instance.getFileKey(
          file.encryptedKey!,
          file.keyDecryptionNonce!,
          collectionKey,
        );
        final encodedMetadata = await CryptoUtil.decryptData(
          CryptoUtil.base642bin(item["metadata"]["encryptedData"]),
          fileKey,
          CryptoUtil.base642bin(file.metadataDecryptionHeader!),
        );
        final Map<String, dynamic> metadata =
            jsonDecode(utf8.decode(encodedMetadata));
        file.applyMetadata(metadata);
        if (item['magicMetadata'] != null) {
          final utfEncodedMmd = await CryptoUtil.decryptData(
            CryptoUtil.base642bin(item['magicMetadata']['data']),
            fileKey,
            CryptoUtil.base642bin(item['magicMetadata']['header']),
          );
          file.mMdEncodedJson = utf8.decode(utfEncodedMmd);
          file.mMdVersion = item['magicMetadata']['version'];
          file.magicMetadata =
              MagicMetadata.fromEncodedJson(file.mMdEncodedJson!);
        }
        if (item['pubMagicMetadata'] != null) {
          final utfEncodedMmd = await CryptoUtil.decryptData(
            CryptoUtil.base642bin(item['pubMagicMetadata']['data']),
            fileKey,
            CryptoUtil.base642bin(item['pubMagicMetadata']['header']),
          );
          file.pubMmdEncodedJson = utf8.decode(utfEncodedMmd);
          file.pubMmdVersion = item['pubMagicMetadata']['version'];
          file.pubMagicMetadata =
              PubMagicMetadata.fromEncodedJson(file.pubMmdEncodedJson!);
        }
        updatedFiles.add(file);
      }
      _logger.info('[Collection-$collectionID] parsed ${diff.length} '
          'diff items ( ${updatedFiles.length} updated) in ${DateTime.now().difference(startTime).inMilliseconds}ms');
      return Diff(updatedFiles, deletedFiles, hasMore, latestUpdatedAtTime);
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  Future<Collection> _fromRemoteCollection(
    Map<String, dynamic>? collectionData,
  ) async {
    final Collection collection = Collection.fromMap(collectionData);
    if (collectionData != null && !collection.isDeleted) {
      final collectionKey = CryptoHelper.instance.getCollectionKey(collection);
      if (collectionData['magicMetadata'] != null) {
        final utfEncodedMmd = await CryptoUtil.decryptData(
          CryptoUtil.base642bin(collectionData['magicMetadata']['data']),
          collectionKey,
          CryptoUtil.base642bin(collectionData['magicMetadata']['header']),
        );
        collection.mMdEncodedJson = utf8.decode(utfEncodedMmd);
        collection.mMdVersion = collectionData['magicMetadata']['version'];
        collection.magicMetadata = CollectionMagicMetadata.fromEncodedJson(
          collection.mMdEncodedJson ?? '{}',
        );
      }

      if (collectionData['pubMagicMetadata'] != null) {
        final utfEncodedMmd = await CryptoUtil.decryptData(
          CryptoUtil.base642bin(collectionData['pubMagicMetadata']['data']),
          collectionKey,
          CryptoUtil.base642bin(
            collectionData['pubMagicMetadata']['header'],
          ),
        );
        collection.mMdPubEncodedJson = utf8.decode(utfEncodedMmd);
        collection.mMbPubVersion =
            collectionData['pubMagicMetadata']['version'];
        collection.pubMagicMetadata =
            CollectionPubMagicMetadata.fromEncodedJson(
          collection.mMdPubEncodedJson ?? '{}',
        );
      }
      if (collectionData['sharedMagicMetadata'] != null) {
        final utfEncodedMmd = await CryptoUtil.decryptData(
          CryptoUtil.base642bin(
            collectionData['sharedMagicMetadata']['data'],
          ),
          collectionKey,
          CryptoUtil.base642bin(
            collectionData['sharedMagicMetadata']['header'],
          ),
        );
        collection.sharedMmdJson = utf8.decode(utfEncodedMmd);
        collection.sharedMmdVersion =
            collectionData['sharedMagicMetadata']['version'];
        collection.sharedMagicMetadata = ShareeMagicMetadata.fromEncodedJson(
          collection.sharedMmdJson ?? '{}',
        );
      }
    }
    collection.setName(_getDecryptedCollectionName(collection));
    return collection;
  }

  String _getDecryptedCollectionName(Collection collection) {
    if (collection.isDeleted) {
      return "Deleted Collection";
    }
    if (collection.encryptedName != null &&
        collection.encryptedName!.isNotEmpty) {
      try {
        final collectionKey =
            CryptoHelper.instance.getCollectionKey(collection);
        final result = CryptoUtil.decryptSync(
          CryptoUtil.base642bin(collection.encryptedName!),
          collectionKey,
          CryptoUtil.base642bin(collection.nameDecryptionNonce!),
        );
        return utf8.decode(result);
      } catch (e, s) {
        _logger.severe(
          "failed to decrypt collection name: ${collection.id}",
          e,
          s,
        );
      }
    }
    return collection.name ?? "Untitled";
  }

  Future<Collection> create(String name, CollectionType type) async {
    final collectionKey = CryptoUtil.generateKey();
    final encryptedKeyData =
        CryptoUtil.encryptSync(collectionKey, _config.getKey()!);
    final encryptedName = CryptoUtil.encryptSync(
      utf8.encode(name),
      collectionKey,
    );
    final request = CreateRequest(
      encryptedKey: CryptoUtil.bin2base64(encryptedKeyData.encryptedData!),
      keyDecryptionNonce: CryptoUtil.bin2base64(encryptedKeyData.nonce!),
      encryptedName: CryptoUtil.bin2base64(encryptedName.encryptedData!),
      nameDecryptionNonce: CryptoUtil.bin2base64(encryptedName.nonce!),
      type: type,
      attributes: CollectionAttributes(),
    );
    return _enteDio
        .post(
      "/collections",
      data: request.toJson(),
    )
        .then((response) async {
      final collectionData = response.data["collection"];
      final collection = await _fromRemoteCollection(collectionData);
      return collection;
    });
  }
}

class CreateRequest {
  String encryptedKey;
  String keyDecryptionNonce;
  String encryptedName;
  String nameDecryptionNonce;
  CollectionType type;
  CollectionAttributes? attributes;
  MetadataRequest? magicMetadata;

  CreateRequest({
    required this.encryptedKey,
    required this.keyDecryptionNonce,
    required this.encryptedName,
    required this.nameDecryptionNonce,
    required this.type,
    this.attributes,
    this.magicMetadata,
  });

  CreateRequest copyWith({
    String? encryptedKey,
    String? keyDecryptionNonce,
    String? encryptedName,
    String? nameDecryptionNonce,
    CollectionType? type,
    CollectionAttributes? attributes,
    MetadataRequest? magicMetadata,
  }) =>
      CreateRequest(
        encryptedKey: encryptedKey ?? this.encryptedKey,
        keyDecryptionNonce: keyDecryptionNonce ?? this.keyDecryptionNonce,
        encryptedName: encryptedName ?? this.encryptedName,
        nameDecryptionNonce: nameDecryptionNonce ?? this.nameDecryptionNonce,
        type: type ?? this.type,
        attributes: attributes ?? this.attributes,
        magicMetadata: magicMetadata ?? this.magicMetadata,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['encryptedKey'] = encryptedKey;
    map['keyDecryptionNonce'] = keyDecryptionNonce;
    map['encryptedName'] = encryptedName;
    map['nameDecryptionNonce'] = nameDecryptionNonce;
    map['type'] = typeToString(type);
    if (attributes != null) {
      map['attributes'] = attributes!.toMap();
    }
    if (magicMetadata != null) {
      map['magicMetadata'] = magicMetadata!.toJson();
    }
    return map;
  }
}
