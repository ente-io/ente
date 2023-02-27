import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/api/collection/create_request.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/file_magic_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/dialog_util.dart';

extension HiddenService on CollectionsService {
  static final _logger = Logger("HiddenCollectionService");

  // getDefaultHiddenCollection will return null if there's no default
  // collection
  Future<Collection> getDefaultHiddenCollection() async {
    if (cachedDefaultHiddenCollection != null) {
      return cachedDefaultHiddenCollection!;
    }
    final int userID = config.getUserID()!;
    final Collection? defaultHidden =
        collectionIDToCollections.values.firstWhereOrNull(
      (element) => element.isDefaultHidden() && element.owner!.id == userID,
    );
    if (defaultHidden != null) {
      cachedDefaultHiddenCollection = defaultHidden;
      return cachedDefaultHiddenCollection!;
    }
    final Collection createdHiddenCollection =
        await _createDefaultHiddenAlbum();
    cachedDefaultHiddenCollection = createdHiddenCollection;
    return cachedDefaultHiddenCollection!;
  }

  // getUncategorizedCollection will return the uncategorized collection
  // for the given user
  Future<Collection> getUncategorizedCollection() async {
    if (cachedUncategorizedCollection != null) {
      return cachedUncategorizedCollection!;
    }
    final int userID = config.getUserID()!;
    final Collection? matchedCollection =
        collectionIDToCollections.values.firstWhereOrNull(
      (element) =>
          element.type == CollectionType.uncategorized &&
          element.owner!.id == userID,
    );
    if (matchedCollection != null) {
      cachedUncategorizedCollection = matchedCollection;
      return cachedUncategorizedCollection!;
    }
    return _createUncategorizedCollection();
  }

  Future<bool> hideFiles(
    BuildContext context,
    List<File> filesToHide, {
    bool forceHide = false,
  }) async {
    final int userID = config.getUserID()!;
    final List<int> uploadedIDs = <int>[];
    final dialog = createProgressDialog(
      context,
      "Hiding...",
    );
    await dialog.show();
    try {
      for (File file in filesToHide) {
        if (file.uploadedFileID == null) {
          throw AssertionError("Can only hide uploaded files");
        }
        if (file.ownerID != userID) {
          throw AssertionError("Can only hide files owned by user");
        }
        uploadedIDs.add(file.uploadedFileID!);
      }

      final defaultHiddenCollection = await getDefaultHiddenCollection();
      final Map<int, List<File>> collectionToFilesMap =
          await filesDB.getAllFilesGroupByCollectionID(uploadedIDs);
      for (MapEntry<int, List<File>> entry in collectionToFilesMap.entries) {
        if (entry.key == defaultHiddenCollection.id) {
          _logger.finest('file already part of hidden collection');
          continue;
        }
        await move(defaultHiddenCollection.id, entry.key, entry.value);
      }
      Bus.instance.fire(
        LocalPhotosUpdatedEvent(
          filesToHide,
          type: EventType.hide,
          source: "hideFiles",
        ),
      );

      await dialog.hide();
    } on AssertionError catch (e) {
      await dialog.hide();
      showErrorDialog(context, "Oops", e.message as String);
      return false;
    } catch (e, s) {
      _logger.severe("Could not hide", e, s);
      await dialog.hide();
      showGenericErrorDialog(context: context);
      return false;
    } finally {
      await dialog.hide();
    }
    return true;
  }

  Future<Collection> _createDefaultHiddenAlbum() async {
    final CreateRequest createRequest = await buildCollectionCreateRequest(
      ".Hidden",
      visibility: visibilityHidden,
      subType: subTypeDefaultHidden,
    );
    _logger.info("Creating Hidden Collection");
    final collection = await createAndCacheCollection(createRequest);
    _logger.info("Creating Hidden Collection Created Successfully");
    final Collection collectionFromServer =
        await fetchCollectionByID(collection.id);
    _logger.info("Fetched Created Hidden Collection Successfully");
    return collectionFromServer;
  }

  Future<Collection> _createUncategorizedCollection() async {
    final uncategorizedCollectionKey = CryptoUtil.generateKey();
    final encKey =
        CryptoUtil.encryptSync(uncategorizedCollectionKey, config.getKey()!);
    final encName = CryptoUtil.encryptSync(
      utf8.encode("Uncategorized") as Uint8List,
      uncategorizedCollectionKey,
    );
    final collection = await createAndCacheCollection(
      CreateRequest(
        encryptedKey: CryptoUtil.bin2base64(encKey.encryptedData!),
        keyDecryptionNonce: CryptoUtil.bin2base64(encKey.nonce!),
        encryptedName: CryptoUtil.bin2base64(encName.encryptedData!),
        nameDecryptionNonce: CryptoUtil.bin2base64(encName.nonce!),
        type: CollectionType.uncategorized,
        attributes: CollectionAttributes(),
      ),
    );
    cachedUncategorizedCollection = collection;
    return cachedUncategorizedCollection!;
  }

  Future<CreateRequest> buildCollectionCreateRequest(
    String name, {
    required int visibility,
    required int subType,
  }) async {
    final collectionKey = CryptoUtil.generateKey();
    final encryptedKeyData =
        CryptoUtil.encryptSync(collectionKey, config.getKey()!);
    final encryptedName = CryptoUtil.encryptSync(
      utf8.encode(name) as Uint8List,
      collectionKey,
    );
    final jsonToUpdate = CollectionMagicMetadata(
      visibility: visibility,
      subType: subType,
    ).toJson();
    assert(jsonToUpdate.length == 2, "metadata should have two keys");
    final encryptedMMd = await CryptoUtil.encryptChaCha(
      utf8.encode(jsonEncode(jsonToUpdate)) as Uint8List,
      collectionKey,
    );
    final MetadataRequest metadataRequest = MetadataRequest(
      version: 1,
      count: jsonToUpdate.length,
      data: CryptoUtil.bin2base64(encryptedMMd.encryptedData!),
      header: CryptoUtil.bin2base64(encryptedMMd.header!),
    );
    final CreateRequest createRequest = CreateRequest(
      encryptedKey: CryptoUtil.bin2base64(encryptedKeyData.encryptedData!),
      keyDecryptionNonce: CryptoUtil.bin2base64(encryptedKeyData.nonce!),
      encryptedName: CryptoUtil.bin2base64(encryptedName.encryptedData!),
      nameDecryptionNonce: CryptoUtil.bin2base64(encryptedName.nonce!),
      type: CollectionType.album,
      attributes: CollectionAttributes(),
      magicMetadata: metadataRequest,
    );
    return createRequest;
  }
}
