import "dart:async";
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:ente_crypto/ente_crypto.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import "package:photos/core/constants.dart";
import 'package:photos/core/event_bus.dart';
import "package:photos/db/files_db.dart";
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/api/collection/create_request.dart';
import "package:photos/models/api/metadata.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/metadata/collection_magic.dart";
import "package:photos/models/metadata/common_keys.dart";
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/dialog_util.dart';

extension HiddenService on CollectionsService {
  static final _logger = Logger("HiddenCollectionService");

  Future<Collection> getDefaultHiddenCollection() async {
    Collection? defaultHidden;
    if (cachedDefaultHiddenCollection != null) {
      return cachedDefaultHiddenCollection!;
    }
    final int userID = config.getUserID()!;
    final allDefaultHidden = collectionIDToCollections.values
        .where(
          (element) => element.isDefaultHidden() && element.owner.id == userID,
        )
        .toList();

    if (allDefaultHidden.length > 1) {
      defaultHidden = await clubAllDefaultHiddenToOne(
        allDefaultHidden,
      );
    } else if (allDefaultHidden.length == 1) {
      defaultHidden = allDefaultHidden.first;
    }

    if (defaultHidden != null) {
      cachedDefaultHiddenCollection = defaultHidden;
      return cachedDefaultHiddenCollection!;
    }

    final Collection createdHiddenCollection =
        await _createDefaultHiddenAlbum();
    cachedDefaultHiddenCollection = createdHiddenCollection;
    return cachedDefaultHiddenCollection!;
  }

  Future<Collection> clubAllDefaultHiddenToOne(
    List<Collection> allDefaultHidden,
  ) async {
    // select first collection as default hidden where all files will be clubbed
    final Collection defaultHidden = allDefaultHidden.first;
    for (Collection hidden in allDefaultHidden) {
      try {
        if (hidden.id == defaultHidden.id) {
          continue;
        }
        final filesInCollection = (await FilesDB.instance.getFilesInCollection(
          hidden.id,
          galleryLoadStartTime,
          galleryLoadEndTime,
        ))
            .files;
        await move(
          filesInCollection,
          toCollectionID: defaultHidden.id,
          fromCollectionID: hidden.id,
        );
        await CollectionsService.instance.trashEmptyCollection(hidden);
      } catch (e, s) {
        _logger.severe(
          "One iteration of clubbing all default hidden failed",
          e,
          s,
        );
        continue;
      }
    }

    return defaultHidden;
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
          element.owner.id == userID,
    );
    if (matchedCollection != null) {
      cachedUncategorizedCollection = matchedCollection;
      return cachedUncategorizedCollection!;
    }
    return _createUncategorizedCollection();
  }

  Future<bool> hideFiles(
    BuildContext context,
    List<EnteFile> filesToHide, {
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
      for (EnteFile file in filesToHide) {
        if (file.uploadedFileID == null) {
          throw AssertionError("Can only hide uploaded files");
        }
        if (file.ownerID != userID) {
          throw AssertionError("Can only hide files owned by user");
        }
        uploadedIDs.add(file.uploadedFileID!);
      }

      final defaultHiddenCollection = await getDefaultHiddenCollection();
      final Map<int, List<EnteFile>> collectionToFilesMap =
          await filesDB.getAllFilesGroupByCollectionID(uploadedIDs);
      for (MapEntry<int, List<EnteFile>> entry
          in collectionToFilesMap.entries) {
        if (entry.key == defaultHiddenCollection.id) {
          _logger.info('file already part of hidden collection');
          continue;
        }
        final Collection? c = getCollectionByID(entry.key);
        // if the collection is not owned by the user, remove the file from the
        // collection
        if (c != null && !c.isOwner(userID)) {
          await removeFromCollection(entry.key, entry.value);
        } else {
          await move(
            entry.value,
            toCollectionID: defaultHiddenCollection.id,
            fromCollectionID: entry.key,
          );
        }
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
      unawaited(
        showErrorDialog(
          context,
          AppLocalizations.of(context).oops,
          e.message as String,
        ),
      );
      return false;
    } catch (e, s) {
      _logger.severe("Could not hide", e, s);
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
      return false;
    } finally {
      await dialog.hide();
    }
    return true;
  }

  Future<Collection> createHiddenAlbum(String name) async {
    final CreateRequest createRequest = await buildCollectionCreateRequest(
      name,
      visibility: hiddenVisibility,
      subType: 0,
    );
    _logger.info("Creating Hidden Collection");
    final collection = await createAndCacheCollection(createRequest);
    _logger.info("Creating Hidden Collection Created Successfully");
    final Collection collectionFromServer =
        await fetchCollectionByID(collection.id);
    _logger.info("Fetched Created Hidden Collection Successfully");
    return collectionFromServer;
  }

  Future<Collection> _createDefaultHiddenAlbum() async {
    final CreateRequest createRequest = await buildCollectionCreateRequest(
      ".Hidden",
      visibility: hiddenVisibility,
      subType: subTypeDefaultHidden,
    );
    _logger.info("Creating Default Hidden Collection");
    final collection = await createAndCacheCollection(createRequest);
    _logger.info("Default Hidden Collection Created Successfully");
    final Collection collectionFromServer =
        await fetchCollectionByID(collection.id);
    _logger.info("Fetched Created Default Hidden Collection Successfully");
    return collectionFromServer;
  }

  Future<Collection> _createUncategorizedCollection() async {
    final uncategorizedCollectionKey = CryptoUtil.generateKey();
    final encKey =
        CryptoUtil.encryptSync(uncategorizedCollectionKey, config.getKey()!);
    final encName = CryptoUtil.encryptSync(
      utf8.encode("Uncategorized"),
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
      utf8.encode(name),
      collectionKey,
    );
    final jsonToUpdate = CollectionMagicMetadata(
      visibility: visibility,
      subType: subType,
    ).toJson();
    assert(jsonToUpdate.length == 2, "metadata should have two keys");
    final encryptedMMd = await CryptoUtil.encryptChaCha(
      utf8.encode(jsonEncode(jsonToUpdate)),
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
