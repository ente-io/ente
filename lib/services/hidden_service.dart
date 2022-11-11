import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
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
      return cachedDefaultHiddenCollection;
    }
    final int userID = config.getUserID()!;
    final Collection? defaultHidden =
        collectionIDToCollections.values.firstWhereOrNull(
      (element) => element.isDefaultHidden() && element.owner!.id == userID,
    );
    if (defaultHidden != null) {
      cachedDefaultHiddenCollection = defaultHidden;
      return cachedDefaultHiddenCollection;
    }
    final Collection createdHiddenCollection =
        await _createDefaultHiddenAlbum();
    cachedDefaultHiddenCollection = createdHiddenCollection;
    return cachedDefaultHiddenCollection;
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
      Bus.instance.fire(ForceReloadHomeGalleryEvent("hideFiles"));
      Bus.instance.fire(
        LocalPhotosUpdatedEvent(filesToHide, type: EventType.unarchived),
      );

      await dialog.hide();
    } on AssertionError catch (e) {
      await dialog.hide();
      showErrorDialog(context, "Oops", e.message as String);
    } catch (e, s) {
      _logger.severe("Could not hide", e, s);
      await dialog.hide();
      showGenericErrorDialog(context);
      return false;
    } finally {
      await dialog.hide();
    }
    return true;
  }

  Future<Collection> _createDefaultHiddenAlbum() async {
    final key = CryptoUtil.generateKey();
    final encryptedKeyData = CryptoUtil.encryptSync(key, config.getKey()!);
    final encryptedName = CryptoUtil.encryptSync(
      utf8.encode(".Hidden") as Uint8List,
      key,
    );
    final jsonToUpdate = CollectionMagicMetadata(
      visibility: visibilityHidden,
      subType: subTypeDefaultHidden,
    ).toJson();
    assert(jsonToUpdate.length == 2, "metadata should have two keys");
    final encryptedMMd = await CryptoUtil.encryptChaCha(
      utf8.encode(jsonEncode(jsonToUpdate)) as Uint8List,
      key,
    );
    final MetadataRequest metadataRequest = MetadataRequest(
      version: 1,
      count: jsonToUpdate.length,
      data: Sodium.bin2base64(encryptedMMd.encryptedData!),
      header: Sodium.bin2base64(encryptedMMd.header!),
    );
    final CreateRequest createRequest = CreateRequest(
      encryptedKey: Sodium.bin2base64(encryptedKeyData.encryptedData!),
      keyDecryptionNonce: Sodium.bin2base64(encryptedKeyData.nonce!),
      encryptedName: Sodium.bin2base64(encryptedName.encryptedData!),
      nameDecryptionNonce: Sodium.bin2base64(encryptedName.nonce!),
      type: CollectionType.album.toString(),
      attributes: CollectionAttributes(),
      magicMetadata: metadataRequest,
    );

    _logger.info("Creating Hidden Collection");
    final collection =
        await createAndCacheCollection(null, createRequest: createRequest);
    _logger.info("Creating Hidden Collection Created Successfully");
    final Collection collectionFromServer =
        await fetchCollectionByID(collection.id);
    _logger.info("Fetched Created Hidden Collection Successfully");
    return collectionFromServer;
  }
}
