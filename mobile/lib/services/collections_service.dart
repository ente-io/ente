import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/collections_db.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/extensions/list.dart';
import 'package:photos/extensions/stop_watch.dart';
import 'package:photos/models/api/collection/create_request.dart';
import "package:photos/models/api/collection/public_url.dart";
import "package:photos/models/api/collection/user.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_file_item.dart';
import 'package:photos/models/collection/collection_items.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/files_split.dart";
import "package:photos/models/metadata/collection_magic.dart";
import 'package:photos/services/app_lifecycle_service.dart';
import "package:photos/services/favorites_service.dart";
import 'package:photos/services/file_magic_service.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_download_util.dart';
import "package:photos/utils/local_settings.dart";
import 'package:shared_preferences/shared_preferences.dart';

class CollectionsService {
  static const _collectionSyncTimeKeyPrefix = "collection_sync_time_";
  static const _collectionsSyncTimeKey = "collections_sync_time_x";

  static const int kMaximumWriteAttempts = 5;

  final _logger = Logger("CollectionsService");

  late CollectionsDB _db;
  late FilesDB _filesDB;
  late Configuration _config;
  late SharedPreferences _prefs;

  final _enteDio = NetworkClient.instance.enteDio;
  final _localPathToCollectionID = <String, int>{};
  final _collectionIDToCollections = <int, Collection>{};
  final _cachedKeys = <int, Uint8List>{};
  final _cachedUserIdToUser = <int, User>{};
  Collection? cachedDefaultHiddenCollection;
  Future<Map<int, int>>? _collectionIDToNewestFileTime;
  Collection? cachedUncategorizedCollection;
  final Map<String, EnteFile> _coverCache = <String, EnteFile>{};
  final Map<int, int> _countCache = <int, int>{};

  CollectionsService._privateConstructor() {
    _db = CollectionsDB.instance;
    _filesDB = FilesDB.instance;
    _config = Configuration.instance;
  }

  static final CollectionsService instance =
      CollectionsService._privateConstructor();

  Future<void> init(SharedPreferences preferences) async {
    _prefs = preferences;
    final collections = await _db.getAllCollections();

    for (final collection in collections) {
      // using deprecated method because the path is stored in encrypted
      // format in the DB
      _cacheCollectionAttributes(collection);
    }
    Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      _collectionIDToNewestFileTime = null;
      if (event.collectionID != null) {
        _coverCache.removeWhere(
          (key, value) => key.startsWith(event.collectionID!.toString()),
        );
        _countCache.remove(event.collectionID);
      }
    });
  }

  Configuration get config => _config;

  Map<int, Collection> get collectionIDToCollections =>
      _collectionIDToCollections;

  FilesDB get filesDB => _filesDB;

  // sync method fetches just sync the collections, not the individual files
  // within the collection.
  Future<void> sync() async {
    _logger.info("Syncing collections");
    final EnteWatch watch = EnteWatch("syncCollection")..start();
    final lastCollectionUpdationTime =
        _prefs.getInt(_collectionsSyncTimeKey) ?? 0;

    // Might not have synced the collection fully
    final fetchedCollections =
        await _fetchCollections(lastCollectionUpdationTime);
    watch.log("remote fetch collections ${fetchedCollections.length}");
    if (fetchedCollections.isEmpty) {
      return;
    }
    final updatedCollections = <Collection>[];
    int maxUpdationTime = lastCollectionUpdationTime;
    final ownerID = _config.getUserID();
    bool shouldFireDeleteEvent = false;
    for (final collection in fetchedCollections) {
      if (collection.isDeleted) {
        await _filesDB.deleteCollection(collection.id);
        await setCollectionSyncTime(collection.id, null);
        if (_collectionIDToCollections.containsKey(collection.id)) {
          shouldFireDeleteEvent = true;
        }
      }
      // remove reference for incoming collections when unshared/deleted
      if (collection.isDeleted && ownerID != collection.owner?.id) {
        await _db.deleteCollection(collection.id);
      } else {
        // keep entry for deletedCollection as collectionKey may be used during
        // trash file decryption
        updatedCollections.add(collection);
      }
      maxUpdationTime = collection.updationTime > maxUpdationTime
          ? collection.updationTime
          : maxUpdationTime;
    }
    if (shouldFireDeleteEvent) {
      Bus.instance.fire(
        LocalPhotosUpdatedEvent(
          List<EnteFile>.empty(),
          source: "syncCollectionDeleted",
        ),
      );
    }
    await _updateDB(updatedCollections);
    await _prefs.setInt(_collectionsSyncTimeKey, maxUpdationTime);
    watch.logAndReset("till DB insertion ${updatedCollections.length}");
    for (final collection in fetchedCollections) {
      _cacheLocalPathAndCollection(collection);
    }
    _logger.info("Collections synced");
    watch.log("${fetchedCollections.length} collection cached refreshed ");
    if (fetchedCollections.isNotEmpty) {
      Bus.instance.fire(
        CollectionUpdatedEvent(
          null,
          List<EnteFile>.empty(),
          "collections_updated",
        ),
      );
    }
  }

  void clearCache() {
    _localPathToCollectionID.clear();
    _collectionIDToCollections.clear();
    cachedDefaultHiddenCollection = null;
    cachedUncategorizedCollection = null;
    _cachedKeys.clear();
  }

  Future<Map<int, int>> getCollectionIDsToBeSynced() async {
    final idsToRemoveUpdateTimeMap =
        await _db.getActiveIDsAndRemoteUpdateTime();
    final result = <int, int>{};
    for (final MapEntry<int, int> e in idsToRemoveUpdateTimeMap.entries) {
      final int cid = e.key;
      final int remoteUpdateTime = e.value;
      if (remoteUpdateTime > getCollectionSyncTime(cid)) {
        result[cid] = remoteUpdateTime;
      }
    }
    return result;
  }

  bool allowUpload(int collectionID) {
    final Collection? c = _collectionIDToCollections[collectionID];
    if (c == null) {
      _logger.info('discardUpload: collectionMissing $collectionID');
      return false;
    }
    if (c.isDeleted) {
      _logger.info('discardUpload: collectionDeleted $collectionID');
      return false;
    }
    if (!c.isOwner(_config.getUserID()!)) {
      _logger.info('discardUpload: notOwner $collectionID');
      return false;
    }
    return true;
  }

  Future<List<Collection>> getArchivedCollection() async {
    final allCollections = getCollectionsForUI();
    return allCollections
        .where(
          (c) => c.isArchived() && !c.isHidden(),
        )
        .toList();
  }

  List<Collection> getHiddenCollections({bool includeDefaultHidden = true}) {
    if (includeDefaultHidden) {
      return _collectionIDToCollections.values
          .toList()
          .where((element) => element.isHidden())
          .toList();
    } else {
      return _collectionIDToCollections.values
          .toList()
          .where(
            (element) => (element.isHidden() &&
                element.id != cachedDefaultHiddenCollection?.id),
          )
          .toList();
    }
  }

  Set<int> getHiddenCollectionIds() {
    return _collectionIDToCollections.values
        .toList()
        .where((element) => element.isHidden())
        .map((e) => e.id)
        .toSet();
  }

  Set<int> archivedOrHiddenCollectionIds() {
    return _collectionIDToCollections.values
        .toList()
        .where(
          (element) =>
              element.hasShareeArchived() ||
              element.isHidden() ||
              element.isArchived(),
        )
        .map((e) => e.id)
        .toSet();
  }

  int getCollectionSyncTime(int collectionID) {
    return _prefs
            .getInt(_collectionSyncTimeKeyPrefix + collectionID.toString()) ??
        0;
  }

  Future<Map<int, int>> getCollectionIDToNewestFileTime() {
    _collectionIDToNewestFileTime ??=
        _filesDB.getCollectionIDToMaxCreationTime();
    return _collectionIDToNewestFileTime!;
  }

  Future<EnteFile?> getCover(Collection c) async {
    final int localSyncTime = getCollectionSyncTime(c.id);
    final String coverKey = '${c.id}_${localSyncTime}_${c.updationTime}';
    if (_coverCache.containsKey(coverKey)) {
      return Future.value(_coverCache[coverKey]!);
    }
    if (kDebugMode) {
      debugPrint("getCover for collection ${c.id} ${c.displayName}");
    }
    if (c.hasCover) {
      final coverID = c.pubMagicMetadata.coverID ?? 0;
      final EnteFile? cover = await filesDB.getUploadedFile(coverID, c.id);
      if (cover != null) {
        _coverCache[coverKey] = cover;
        return Future.value(cover);
      }
    }
    final coverFile = await filesDB.getCollectionFileFirstOrLast(
      c.id,
      c.pubMagicMetadata.asc ?? false,
    );
    if (coverFile != null) {
      _coverCache[coverKey] = coverFile;
      return Future.value(coverFile);
    }
    return null;
  }

  EnteFile? getCoverCache(Collection c) {
    final int localSyncTime = getCollectionSyncTime(c.id);
    final String coverKey = '${c.id}_${localSyncTime}_${c.updationTime}';
    return _coverCache[coverKey];
  }

  Future<int> getFileCount(Collection c) async {
    if (_countCache.containsKey(c.id)) {
      return _countCache[c.id]!;
    } else {
      final count = await _filesDB.collectionFileCount(c.id);
      _countCache[c.id] = count;
      return count;
    }
  }

  int? getCachedFileCount(Collection c) {
    return _countCache[c.id];
  }

  Future<bool> setCollectionSyncTime(int collectionID, int? time) async {
    final key = _collectionSyncTimeKeyPrefix + collectionID.toString();
    if (time == null) {
      return _prefs.remove(key);
    }
    return _prefs.setInt(key, time);
  }

  // getActiveCollections returns list of collections which are not deleted yet
  List<Collection> getActiveCollections() {
    return _collectionIDToCollections.values
        .toList()
        .where((element) => !element.isDeleted)
        .toList();
  }

  // getActiveCollections returns list of collections which are not deleted yet
  Set<int> nonHiddenOwnedCollections() {
    final int ownerID = _config.getUserID()!;
    return _collectionIDToCollections.values
        .toList()
        .where(
          (element) =>
              !element.isDeleted &&
              !element.isHidden() &&
              element.isOwner(ownerID),
        )
        .map((e) => e.id)
        .toSet();
  }

  // returns collections after removing deleted,uncategorized, and hidden
  // collections
  List<Collection> getCollectionsForUI({
    bool includedShared = false,
    bool includeCollab = false,
    bool includeUncategorized = false,
  }) {
    final Set<CollectionParticipantRole> allowedRoles = {
      CollectionParticipantRole.owner,
    };
    if (includedShared) {
      allowedRoles.add(CollectionParticipantRole.viewer);
    }
    if (includedShared || includeCollab) {
      allowedRoles.add(CollectionParticipantRole.collaborator);
    }
    final int userID = _config.getUserID()!;
    return _collectionIDToCollections.values
        .where(
          (c) =>
              !c.isDeleted &&
              (includeUncategorized ||
                  c.type != CollectionType.uncategorized) &&
              !c.isHidden() &&
              allowedRoles.contains(c.getRole(userID)),
        )
        .toList();
  }

  SharedCollections getSharedCollections() {
    final List<Collection> outgoing = [];
    final List<Collection> incoming = [];
    final List<Collection> quickLinks = [];
    final List<Collection> collections =
        getCollectionsForUI(includedShared: true);
    for (final c in collections) {
      if (c.owner!.id == Configuration.instance.getUserID()) {
        if (c.hasSharees || c.hasLink && !c.isQuickLinkCollection()) {
          outgoing.add(c);
        } else if (c.isQuickLinkCollection()) {
          quickLinks.add(c);
        }
      } else {
        incoming.add(c);
      }
    }
    incoming.sort((first, second) {
      return second.updationTime.compareTo(first.updationTime);
    });
    outgoing.sort((first, second) {
      return second.updationTime.compareTo(first.updationTime);
    });
    return SharedCollections(outgoing, incoming, quickLinks);
  }

  Future<List<Collection>> getCollectionForOnEnteSection() async {
    final AlbumSortKey sortKey = LocalSettings.instance.albumSortKey();
    final List<Collection> collections =
        CollectionsService.instance.getCollectionsForUI();
    final bool hasFavorites = FavoritesService.instance.hasFavorites();
    late Map<int, int> collectionIDToNewestPhotoTime;
    if (sortKey == AlbumSortKey.newestPhoto) {
      collectionIDToNewestPhotoTime =
          await CollectionsService.instance.getCollectionIDToNewestFileTime();
    }
    collections.sort(
      (first, second) {
        if (sortKey == AlbumSortKey.albumName) {
          return compareAsciiLowerCaseNatural(
            first.displayName,
            second.displayName,
          );
        } else if (sortKey == AlbumSortKey.newestPhoto) {
          return (collectionIDToNewestPhotoTime[second.id] ?? -1 * intMaxValue)
              .compareTo(
            collectionIDToNewestPhotoTime[first.id] ?? -1 * intMaxValue,
          );
        } else {
          return second.updationTime.compareTo(first.updationTime);
        }
      },
    );
    final List<Collection> favorites = [];
    final List<Collection> pinned = [];
    final List<Collection> rest = [];
    for (final collection in collections) {
      if (collection.type == CollectionType.uncategorized ||
          collection.isQuickLinkCollection() ||
          collection.isHidden() ||
          collection.isArchived()) {
        continue;
      }
      if (collection.type == CollectionType.favorites) {
        // Hide fav collection if it's empty
        if (hasFavorites) {
          favorites.add(collection);
        }
      } else if (collection.isPinned) {
        pinned.add(collection);
      } else {
        rest.add(collection);
      }
    }

    return favorites + pinned + rest;
  }

  User getFileOwner(int userID, int? collectionID) {
    if (_cachedUserIdToUser.containsKey(userID)) {
      return _cachedUserIdToUser[userID]!;
    }
    if (collectionID != null) {
      final Collection? collection = getCollectionByID(collectionID);
      if (collection != null) {
        if (collection.owner?.id == userID) {
          _cachedUserIdToUser[userID] = collection.owner!;
        } else {
          final matchingUser = collection.getSharees().firstWhereOrNull(
                (u) => u.id == userID,
              );
          if (matchingUser != null) {
            _cachedUserIdToUser[userID] = matchingUser;
          }
        }
      }
    }
    return _cachedUserIdToUser[userID] ??
        User(
          id: userID,
          email: "unknown@unknown.com",
        );
  }

  Future<List<User>> getSharees(int collectionID) {
    return _enteDio.get(
      "/collections/sharees",
      queryParameters: {
        "collectionID": collectionID,
      },
    ).then((response) {
      _logger.info(response.toString());
      final sharees = <User>[];
      for (final user in response.data["sharees"]) {
        sharees.add(User.fromMap(user));
      }
      return sharees;
    });
  }

  String getCastData(
    String castToken,
    Collection collection,
    String publicKey,
  ) {
    final String payload = jsonEncode({
      "collectionID": collection.id,
      "castToken": castToken,
      "collectionKey": CryptoUtil.bin2base64(getCollectionKey(collection.id)),
    });
    final encPayload = CryptoUtil.sealSync(
      CryptoUtil.base642bin(base64Encode(payload.codeUnits)),
      CryptoUtil.base642bin(publicKey),
    );
    return CryptoUtil.bin2base64(encPayload);
  }

  Future<List<User>> share(
    int collectionID,
    String email,
    String publicKey,
    CollectionParticipantRole role,
  ) async {
    final encryptedKey = CryptoUtil.sealSync(
      getCollectionKey(collectionID),
      CryptoUtil.base642bin(publicKey),
    );
    try {
      final response = await _enteDio.post(
        "/collections/share",
        data: {
          "collectionID": collectionID,
          "email": email,
          "encryptedKey": CryptoUtil.bin2base64(encryptedKey),
          "role": role.toStringVal(),
        },
      );
      final sharees = <User>[];
      for (final user in response.data["sharees"]) {
        sharees.add(User.fromMap(user));
      }
      _collectionIDToCollections[collectionID] =
          _collectionIDToCollections[collectionID]!.copyWith(sharees: sharees);
      unawaited(_db.insert([_collectionIDToCollections[collectionID]!]));
      RemoteSyncService.instance.sync(silently: true).ignore();
      return sharees;
    } on DioError catch (e) {
      if (e.response?.statusCode == 402) {
        throw SharingNotPermittedForFreeAccountsError();
      }
      rethrow;
    }
  }

  Future<List<User>> unshare(int collectionID, String email) async {
    try {
      final response = await _enteDio.post(
        "/collections/unshare",
        data: {
          "collectionID": collectionID,
          "email": email,
        },
      );
      final sharees = <User>[];
      for (final user in response.data["sharees"]) {
        sharees.add(User.fromMap(user));
      }
      _collectionIDToCollections[collectionID] =
          _collectionIDToCollections[collectionID]!.copyWith(sharees: sharees);
      unawaited(_db.insert([_collectionIDToCollections[collectionID]!]));
      RemoteSyncService.instance.sync(silently: true).ignore();
      return sharees;
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
  }

  Future<void> trashNonEmptyCollection(
    Collection collection,
  ) async {
    try {
      await _turnOffDeviceFolderSync(collection);
      await _enteDio.delete(
        "/collections/v3/${collection.id}?keepFiles=False&collectionID=${collection.id}",
      );
      await _handleCollectionDeletion(collection);
    } catch (e) {
      _logger.severe('failed to trash collection', e);
      rethrow;
    }
  }

  Future<void> _turnOffDeviceFolderSync(Collection collection) async {
    final deviceCollections = await _filesDB.getDeviceCollections();
    final Map<String, bool> devicePathIDsToUnSync = Map.fromEntries(
      deviceCollections
          .where((e) => e.shouldBackup && e.collectionID == collection.id)
          .map((e) => MapEntry(e.id, false)),
    );

    if (devicePathIDsToUnSync.isNotEmpty) {
      _logger.info(
        'turning off backup status for folders $devicePathIDsToUnSync',
      );
      await RemoteSyncService.instance
          .updateDeviceFolderSyncStatus(devicePathIDsToUnSync);
    }
  }

  Future<void> trashEmptyCollection(
    Collection collection, {
    //  during bulk deletion, this event is not fired to avoid quick refresh
    //  of the collection gallery
    bool isBulkDelete = false,
  }) async {
    try {
      if (!isBulkDelete) {
        await _turnOffDeviceFolderSync(collection);
      }
      // While trashing empty albums, we must pass keepFiles flag as True.
      // The server will verify that the collection is actually empty before
      // deleting the files. If keepFiles is set as False and the collection
      // is not empty, then the files in the collections will be moved to trash.
      await _enteDio.delete(
        "/collections/v3/${collection.id}?keepFiles=True&collectionID=${collection.id}",
      );
      if (isBulkDelete) {
        final deletedCollection = collection.copyWith(isDeleted: true);
        _collectionIDToCollections[collection.id] = deletedCollection;
        unawaited(_db.insert([deletedCollection]));
      } else {
        await _handleCollectionDeletion(collection);
      }
    } on DioError catch (e) {
      if (e.response != null) {
        debugPrint("Error " + e.response!.toString());
      }
      rethrow;
    } catch (e) {
      _logger.severe('failed to trash empty collection', e);
      rethrow;
    }
  }

  Future<void> _handleCollectionDeletion(Collection collection) async {
    await _filesDB.deleteCollection(collection.id);
    final deletedCollection = collection.copyWith(isDeleted: true);
    unawaited(_db.insert([deletedCollection]));
    _collectionIDToCollections[collection.id] = deletedCollection;
    Bus.instance.fire(
      CollectionUpdatedEvent(
        collection.id,
        <EnteFile>[],
        "delete_collection",
        type: EventType.deletedFromRemote,
      ),
    );
    sync().ignore();
    LocalSyncService.instance.syncAll().ignore();
  }

  Uint8List getCollectionKey(int collectionID) {
    if (!_cachedKeys.containsKey(collectionID)) {
      final collection = _collectionIDToCollections[collectionID];
      if (collection == null) {
        // Async fetch for collection. A collection might be
        // missing from older clients when we used to delete the collection
        // from db. For trashed files, we need collection data for decryption.
        fetchCollectionByID(collectionID);
        throw AssertionError('collectionID $collectionID is not cached');
      }
      _cachedKeys[collectionID] =
          _getAndCacheDecryptedKey(collection, source: "getCollectionKey");
    }
    return _cachedKeys[collectionID]!;
  }

  Uint8List _getAndCacheDecryptedKey(
    Collection collection, {
    String source = "",
  }) {
    if (_cachedKeys.containsKey(collection.id)) {
      return _cachedKeys[collection.id]!;
    }
    debugPrint(
      "Compute collection decryption key for ${collection.id} source"
      " $source",
    );
    final encryptedKey = CryptoUtil.base642bin(collection.encryptedKey);
    Uint8List? collectionKey;
    if (collection.owner?.id == _config.getUserID()) {
      // If the collection is owned by the user, decrypt with the master key
      if (_config.getKey() == null) {
        // Possible during AppStore account migration, where SecureStorage
        // would become inaccessible to the new Developer Account
        throw Exception("key can not be null");
      }
      collectionKey = CryptoUtil.decryptSync(
        encryptedKey,
        _config.getKey()!,
        CryptoUtil.base642bin(collection.keyDecryptionNonce!),
      );
    } else {
      // If owned by a different user, decrypt with the public key
      collectionKey = CryptoUtil.openSealSync(
        encryptedKey,
        CryptoUtil.base642bin(_config.getKeyAttributes()!.publicKey),
        _config.getSecretKey()!,
      );
    }
    _cachedKeys[collection.id] = collectionKey;
    return collectionKey;
  }

  Future<void> rename(Collection collection, String newName) async {
    try {
      // Note: when collection created to sharing few files is renamed
      // convert that collection to a regular collection type.
      if (collection.isQuickLinkCollection()) {
        await updateMagicMetadata(collection, {"subType": 0});
      }
      final encryptedName = CryptoUtil.encryptSync(
        utf8.encode(newName) as Uint8List,
        getCollectionKey(collection.id),
      );
      await _enteDio.post(
        "/collections/rename",
        data: {
          "collectionID": collection.id,
          "encryptedName": CryptoUtil.bin2base64(encryptedName.encryptedData!),
          "nameDecryptionNonce": CryptoUtil.bin2base64(encryptedName.nonce!),
        },
      );
      collection.setName(newName);
      sync().ignore();
    } catch (e, s) {
      _logger.warning("failed to rename collection", e, s);
      rethrow;
    }
  }

  Future<void> leaveAlbum(Collection collection) async {
    try {
      await _enteDio.post(
        "/collections/leave/${collection.id}",
      );
      await _handleCollectionDeletion(collection);
    } catch (e, s) {
      _logger.severe("failed to leave collection", e, s);
      rethrow;
    }
  }

  Future<void> updateMagicMetadata(
    Collection collection,
    Map<String, dynamic> newMetadataUpdate,
  ) async {
    final int ownerID = Configuration.instance.getUserID()!;
    try {
      if (collection.owner?.id != ownerID) {
        throw AssertionError("cannot modify albums not owned by you");
      }
      // read the existing magic metadata and apply new updates to existing data
      // current update is simple replace. This will be enhanced in the future,
      // as required.
      final Map<String, dynamic> jsonToUpdate =
          jsonDecode(collection.mMdEncodedJson ?? '{}');
      newMetadataUpdate.forEach((key, value) {
        jsonToUpdate[key] = value;
      });

      final key = getCollectionKey(collection.id);
      final encryptedMMd = await CryptoUtil.encryptChaCha(
        utf8.encode(jsonEncode(jsonToUpdate)) as Uint8List,
        key,
      );
      // for required field, the json validator on golang doesn't treat 0 as valid
      // value. Instead of changing version to ptr, decided to start version with 1.
      final int currentVersion = max(collection.mMdVersion, 1);
      final params = UpdateMagicMetadataRequest(
        id: collection.id,
        magicMetadata: MetadataRequest(
          version: currentVersion,
          count: jsonToUpdate.length,
          data: CryptoUtil.bin2base64(encryptedMMd.encryptedData!),
          header: CryptoUtil.bin2base64(encryptedMMd.header!),
        ),
      );
      await _enteDio.put(
        "/collections/magic-metadata",
        data: params,
      );
      // update the local information so that it's reflected on UI
      collection.mMdEncodedJson = jsonEncode(jsonToUpdate);
      collection.magicMetadata = CollectionMagicMetadata.fromJson(jsonToUpdate);
      collection.mMdVersion = currentVersion + 1;
      _collectionIDToCollections[collection.id] = collection;

      // trigger sync to fetch the latest collection state from server
      sync().ignore();
    } on DioError catch (e) {
      if (e.response != null && e.response?.statusCode == 409) {
        _logger.severe('collection magic data out of sync');
        sync().ignore();
      }
      rethrow;
    } catch (e, s) {
      _logger.severe("failed to sync magic metadata", e, s);
      rethrow;
    }
  }

  Future<void> updatePublicMagicMetadata(
    Collection collection,
    Map<String, dynamic> newMetadataUpdate,
  ) async {
    final int ownerID = Configuration.instance.getUserID()!;
    try {
      if (collection.owner?.id != ownerID) {
        throw AssertionError("cannot modify albums not owned by you");
      }
      // read the existing magic metadata and apply new updates to existing data
      // current update is simple replace. This will be enhanced in the future,
      // as required.
      final Map<String, dynamic> jsonToUpdate =
          jsonDecode(collection.mMdPubEncodedJson ?? '{}');
      newMetadataUpdate.forEach((key, value) {
        jsonToUpdate[key] = value;
      });

      final key = getCollectionKey(collection.id);
      final encryptedMMd = await CryptoUtil.encryptChaCha(
        utf8.encode(jsonEncode(jsonToUpdate)) as Uint8List,
        key,
      );
      // for required field, the json validator on golang doesn't treat 0 as valid
      // value. Instead of changing version to ptr, decided to start version with 1.
      final int currentVersion = max(collection.mMbPubVersion, 1);
      final params = UpdateMagicMetadataRequest(
        id: collection.id,
        magicMetadata: MetadataRequest(
          version: currentVersion,
          count: jsonToUpdate.length,
          data: CryptoUtil.bin2base64(encryptedMMd.encryptedData!),
          header: CryptoUtil.bin2base64(encryptedMMd.header!),
        ),
      );
      await _enteDio.put(
        "/collections/public-magic-metadata",
        data: params,
      );
      // update the local information so that it's reflected on UI
      collection.mMdPubEncodedJson = jsonEncode(jsonToUpdate);
      collection.pubMagicMetadata =
          CollectionPubMagicMetadata.fromJson(jsonToUpdate);
      collection.mMbPubVersion = currentVersion + 1;
      _cacheLocalPathAndCollection(collection);
      // trigger sync to fetch the latest collection state from server
      sync().ignore();
    } on DioError catch (e) {
      if (e.response != null && e.response?.statusCode == 409) {
        _logger.severe('collection magic data out of sync');
        sync().ignore();
      }
      rethrow;
    } catch (e, s) {
      _logger.severe("failed to sync magic metadata", e, s);
      rethrow;
    }
  }

  Future<void> updateShareeMagicMetadata(
    Collection collection,
    Map<String, dynamic> newMetadataUpdate,
  ) async {
    final int ownerID = Configuration.instance.getUserID()!;
    try {
      if (collection.owner?.id == ownerID) {
        throw AssertionError("cannot modify sharee settings for albums owned "
            "by you");
      }
      // read the existing magic metadata and apply new updates to existing data
      // current update is simple replace. This will be enhanced in the future,
      // as required.
      final Map<String, dynamic> jsonToUpdate =
          jsonDecode(collection.sharedMmdJson ?? '{}');
      newMetadataUpdate.forEach((key, value) {
        jsonToUpdate[key] = value;
      });

      final key = getCollectionKey(collection.id);
      final encryptedMMd = await CryptoUtil.encryptChaCha(
        utf8.encode(jsonEncode(jsonToUpdate)) as Uint8List,
        key,
      );
      // for required field, the json validator on golang doesn't treat 0 as valid
      // value. Instead of changing version to ptr, decided to start version with 1.
      final int currentVersion = max(collection.sharedMmdVersion, 1);
      final params = UpdateMagicMetadataRequest(
        id: collection.id,
        magicMetadata: MetadataRequest(
          version: currentVersion,
          count: jsonToUpdate.length,
          data: CryptoUtil.bin2base64(encryptedMMd.encryptedData!),
          header: CryptoUtil.bin2base64(encryptedMMd.header!),
        ),
      );
      await _enteDio.put(
        "/collections/sharee-magic-metadata",
        data: params,
      );
      // update the local information so that it's reflected on UI
      collection.sharedMmdJson = jsonEncode(jsonToUpdate);
      collection.sharedMagicMetadata =
          ShareeMagicMetadata.fromJson(jsonToUpdate);
      collection.sharedMmdVersion = currentVersion + 1;
      _cacheLocalPathAndCollection(collection);
      // trigger sync to fetch the latest collection state from server
      sync().ignore();
    } on DioError catch (e) {
      if (e.response != null && e.response?.statusCode == 409) {
        _logger.severe('collection magic data out of sync');
        sync().ignore();
      }
      rethrow;
    } catch (e, s) {
      _logger.severe("failed to sync magic metadata", e, s);
      rethrow;
    }
  }

  Future<void> createShareUrl(
    Collection collection, {
    bool enableCollect = false,
  }) async {
    try {
      final response = await _enteDio.post(
        "/collections/share-url",
        data: {
          "collectionID": collection.id,
          "enableCollect": enableCollect,
        },
      );
      collection.publicURLs?.add(PublicURL.fromMap(response.data["result"]));
      await _db.insert(List.from([collection]));
      _collectionIDToCollections[collection.id] = collection;
      Bus.instance.fire(
        CollectionUpdatedEvent(collection.id, <EnteFile>[], "shareUrL"),
      );
    } on DioError catch (e) {
      if (e.response?.statusCode == 402) {
        throw SharingNotPermittedForFreeAccountsError();
      }
      rethrow;
    } catch (e, s) {
      _logger.severe("failed to rename collection", e, s);
      rethrow;
    }
  }

  Future<void> updateShareUrl(
    Collection collection,
    Map<String, dynamic> prop,
  ) async {
    prop.putIfAbsent('collectionID', () => collection.id);
    try {
      final response = await _enteDio.put(
        "/collections/share-url",
        data: json.encode(prop),
      );
      // remove existing url information
      collection.publicURLs?.clear();
      collection.publicURLs?.add(PublicURL.fromMap(response.data["result"]));
      await _db.insert(List.from([collection]));
      _collectionIDToCollections[collection.id] = collection;
      Bus.instance.fire(
        CollectionUpdatedEvent(collection.id, <EnteFile>[], "updateUrl"),
      );
    } on DioError catch (e) {
      if (e.response?.statusCode == 402) {
        throw SharingNotPermittedForFreeAccountsError();
      }
      rethrow;
    } catch (e, s) {
      _logger.severe("failed to update ShareUrl", e, s);
      rethrow;
    }
  }

  Future<void> disableShareUrl(Collection collection) async {
    try {
      await _enteDio.delete(
        "/collections/share-url/" + collection.id.toString(),
      );
      collection.publicURLs?.clear();
      await _db.insert(List.from([collection]));
      _collectionIDToCollections[collection.id] = collection;
      Bus.instance.fire(
        CollectionUpdatedEvent(
          collection.id,
          <EnteFile>[],
          "disableShareUrl",
        ),
      );
    } on DioError catch (e) {
      _logger.info(e);
      rethrow;
    }
  }

  Future<List<Collection>> _fetchCollections(int sinceTime) async {
    try {
      final response = await _enteDio.get(
        "/collections/v2",
        queryParameters: {
          "sinceTime": sinceTime,
          "source": AppLifecycleService.instance.isForeground ? "fg" : "bg",
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
      if (e is DioError && e.response?.statusCode == 401) {
        throw UnauthorizedError();
      }
      rethrow;
    }
  }

  Future<Collection> _fromRemoteCollection(
    Map<String, dynamic>? collectionData,
  ) async {
    final Collection collection = Collection.fromMap(collectionData);
    if (collectionData != null && !collection.isDeleted) {
      final collectionKey =
          _getAndCacheDecryptedKey(collection, source: "fetchDecryptMeta");
      if (collectionData['magicMetadata'] != null) {
        final utfEncodedMmd = await CryptoUtil.decryptChaCha(
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
        final utfEncodedMmd = await CryptoUtil.decryptChaCha(
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
        final utfEncodedMmd = await CryptoUtil.decryptChaCha(
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
    if (collection.canLinkToDevicePath(_config.getUserID()!)) {
      collection.decryptedPath = (_decryptCollectionPath(collection));
    }
    return collection;
  }

  Collection? getCollectionByID(int collectionID) {
    return _collectionIDToCollections[collectionID];
  }

  Future<Collection> createAlbum(String albumName) async {
    final collectionKey = CryptoUtil.generateKey();
    final encryptedKeyData =
        CryptoUtil.encryptSync(collectionKey, _config.getKey()!);
    final encryptedName = CryptoUtil.encryptSync(
      utf8.encode(albumName) as Uint8List,
      collectionKey,
    );
    final collection = await createAndCacheCollection(
      CreateRequest(
        encryptedKey: CryptoUtil.bin2base64(encryptedKeyData.encryptedData!),
        keyDecryptionNonce: CryptoUtil.bin2base64(encryptedKeyData.nonce!),
        encryptedName: CryptoUtil.bin2base64(encryptedName.encryptedData!),
        nameDecryptionNonce: CryptoUtil.bin2base64(encryptedName.nonce!),
        type: CollectionType.album,
        attributes: CollectionAttributes(),
      ),
    );
    return collection;
  }

  Future<Collection> fetchCollectionByID(int collectionID) async {
    try {
      _logger.fine('fetching collectionByID $collectionID');
      final response = await _enteDio.get(
        "/collections/$collectionID",
      );
      assert(response.data != null);
      final collectionData = response.data["collection"];
      final collection = await _fromRemoteCollection(collectionData);
      await _db.insert(List.from([collection]));
      _cacheLocalPathAndCollection(collection);
      return collection;
    } catch (e) {
      if (e is DioError && e.response?.statusCode == 401) {
        throw UnauthorizedError();
      }
      _logger.severe('failed to fetch collection: $collectionID', e);
      rethrow;
    }
  }

  Future<Collection> getOrCreateForPath(String path) async {
    if (_localPathToCollectionID.containsKey(path)) {
      final Collection? cachedCollection =
          _collectionIDToCollections[_localPathToCollectionID[path]];
      if (cachedCollection != null &&
          cachedCollection.canLinkToDevicePath(_config.getUserID()!)) {
        return cachedCollection;
      }
    }
    final collectionKey = CryptoUtil.generateKey();
    final encryptedKeyData =
        CryptoUtil.encryptSync(collectionKey, _config.getKey()!);
    final encryptedPath =
        CryptoUtil.encryptSync(utf8.encode(path) as Uint8List, collectionKey);
    final collection = await createAndCacheCollection(
      CreateRequest(
        encryptedKey: CryptoUtil.bin2base64(encryptedKeyData.encryptedData!),
        keyDecryptionNonce: CryptoUtil.bin2base64(encryptedKeyData.nonce!),
        encryptedName: CryptoUtil.bin2base64(encryptedPath.encryptedData!),
        nameDecryptionNonce: CryptoUtil.bin2base64(encryptedPath.nonce!),
        type: CollectionType.folder,
        attributes: CollectionAttributes(
          encryptedPath: CryptoUtil.bin2base64(encryptedPath.encryptedData!),
          pathDecryptionNonce: CryptoUtil.bin2base64(encryptedPath.nonce!),
          version: 1,
        ),
      ),
    );
    return collection;
  }

  Future<void> addOrCopyToCollection(
    int dstCollectionID,
    List<EnteFile> files,
  ) async {
    final splitResult = FilesSplit.split(files, _config.getUserID()!);
    if (splitResult.pendingUploads.isNotEmpty) {
      throw ArgumentError('File should be already uploaded');
    }
    if (splitResult.ownedByCurrentUser.isNotEmpty) {
      await _addToCollection(dstCollectionID, splitResult.ownedByCurrentUser);
    }
    if (splitResult.ownedByOtherUsers.isNotEmpty) {
      late final List<EnteFile> filesToCopy;
      late final List<EnteFile> filesToAdd;
      (filesToAdd, filesToCopy) = (await _splitFilesToAddAndCopy(
        splitResult.ownedByOtherUsers,
      ));

      if (filesToAdd.isNotEmpty) {
        _logger.info(
          "found existing ${filesToAdd.length} files with same hash, adding symlinks",
        );
        await _addToCollection(dstCollectionID, filesToAdd);
      }
      // group files by collectionID
      final Map<int, List<EnteFile>> filesByCollection = {};
      for (final file in filesToCopy) {
        if (filesByCollection.containsKey(file.collectionID!)) {
          filesByCollection[file.collectionID!]!.add(file.copyWith());
        } else {
          filesByCollection[file.collectionID!] = [file.copyWith()];
        }
      }
      for (final entry in filesByCollection.entries) {
        final srcCollectionID = entry.key;
        final files = entry.value;
        await _copyToCollection(
          files,
          dstCollectionID: dstCollectionID,
          srcCollectionID: srcCollectionID,
        );
      }
    }
  }

  Future<void> _addToCollection(int collectionID, List<EnteFile> files) async {
    final containsUploadedFile = files.any((e) => e.isUploaded);
    if (containsUploadedFile) {
      final existingFileIDsInCollection =
          await FilesDB.instance.getUploadedFileIDs(collectionID);
      files.removeWhere(
        (element) =>
            element.uploadedFileID != null &&
            existingFileIDsInCollection.contains(element.uploadedFileID),
      );
    }
    if (files.isEmpty || !containsUploadedFile) {
      _logger.info("nothing to add to the collection");
      return;
    }
    final anyFileOwnedByOther =
        files.any((e) => e.ownerID != null && e.ownerID != _config.getUserID());
    if (anyFileOwnedByOther) {
      throw ArgumentError(
        'Cannot add files owned by other users, they should be copied',
      );
    }

    final params = <String, dynamic>{};
    params["collectionID"] = collectionID;
    final batchedFiles = files.chunks(batchSize);
    for (final batch in batchedFiles) {
      params["files"] = [];
      for (final file in batch) {
        final fileKey = getFileKey(file);
        file.generatedID =
            null; // So that a new entry is created in the FilesDB
        file.collectionID = collectionID;
        final encryptedKeyData =
            CryptoUtil.encryptSync(fileKey, getCollectionKey(collectionID));
        file.encryptedKey =
            CryptoUtil.bin2base64(encryptedKeyData.encryptedData!);
        file.keyDecryptionNonce =
            CryptoUtil.bin2base64(encryptedKeyData.nonce!);
        params["files"].add(
          CollectionFileItem(
            file.uploadedFileID!,
            file.encryptedKey!,
            file.keyDecryptionNonce!,
          ).toMap(),
        );
      }

      try {
        await _enteDio.post(
          "/collections/add-files",
          data: params,
        );
        await _filesDB.insertMultiple(batch);
        Bus.instance.fire(CollectionUpdatedEvent(collectionID, batch, "addTo"));
      } catch (e) {
        rethrow;
      }
    }
  }

  // This method is used to add files to a collection without firing any events.
  // Unlike `addToCollection`, this method does not update the `FilesDB` or modify
  // the `EnteFile` objects passed to it. This is only used during dedupe process
  // for adding files to a collection without firing any events.
  Future<void> addSilentlyToCollection(
    int collectionID,
    List<EnteFile> files,
  ) async {
    if (files.isEmpty) {
      return;
    }
    // as any non uploaded file
    final pendingUpload = files.any(
      (element) => element.uploadedFileID == null,
    );
    if (pendingUpload) {
      throw ArgumentError('Can only add uploaded files silently');
    }
    final existingFileIDsInCollection =
        await FilesDB.instance.getUploadedFileIDs(collectionID);
    files.removeWhere(
      (element) => existingFileIDsInCollection.contains(element.uploadedFileID),
    );
    if (files.isEmpty) {
      _logger.info("nothing to add to the collection");
      return;
    }
    final params = <String, dynamic>{};
    params["collectionID"] = collectionID;
    final batchedFiles = files.chunks(batchSize);
    for (final batch in batchedFiles) {
      params["files"] = [];
      for (final file in batch) {
        final int uploadedFileID = file.uploadedFileID!;
        final fileKey = getFileKey(file);
        final encryptedKeyData =
            CryptoUtil.encryptSync(fileKey, getCollectionKey(collectionID));
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
  }

  Future<void> _copyToCollection(
    List<EnteFile> files, {
    required int dstCollectionID,
    required int srcCollectionID,
  }) async {
    _validateCopyInput(dstCollectionID, srcCollectionID, files);
    final batchedFiles = files.chunks(batchSizeCopy);
    final params = <String, dynamic>{};
    params["dstCollectionID"] = dstCollectionID;
    params["srcCollectionID"] = srcCollectionID;
    for (final batch in batchedFiles) {
      params["files"] = [];
      for (final batchFile in batch) {
        final fileKey = getFileKey(batchFile);
        _logger.info(
          "srcCollection : $srcCollectionID  file: ${batchFile.uploadedFileID}  key: ${CryptoUtil.bin2base64(fileKey)} ",
        );
        final encryptedKeyData =
            CryptoUtil.encryptSync(fileKey, getCollectionKey(dstCollectionID));
        batchFile.encryptedKey =
            CryptoUtil.bin2base64(encryptedKeyData.encryptedData!);
        batchFile.keyDecryptionNonce =
            CryptoUtil.bin2base64(encryptedKeyData.nonce!);
        params["files"].add(
          CollectionFileItem(
            batchFile.uploadedFileID!,
            batchFile.encryptedKey!,
            batchFile.keyDecryptionNonce!,
          ).toMap(),
        );
      }

      try {
        final res = await _enteDio.post(
          "/files/copy",
          data: params,
        );
        final oldToCopiedFileIDMap = Map<int, int>.from(
          (res.data["oldToNewFileIDMap"] as Map<String, dynamic>).map(
            (key, value) => MapEntry(int.parse(key), value as int),
          ),
        );
        for (final file in batch) {
          final int uploadIDForOriginalFIle = file.uploadedFileID!;
          if (oldToCopiedFileIDMap.containsKey(uploadIDForOriginalFIle)) {
            file.generatedID = null;
            file.collectionID = dstCollectionID;
            file.uploadedFileID = oldToCopiedFileIDMap[uploadIDForOriginalFIle];
            file.ownerID = _config.getUserID();
            oldToCopiedFileIDMap.remove(uploadIDForOriginalFIle);
          } else {
            throw Exception("Failed to copy file ${file.uploadedFileID}");
          }
        }
        if (oldToCopiedFileIDMap.isNotEmpty) {
          throw Exception(
            "Failed to map following uploadKey ${oldToCopiedFileIDMap.keys}",
          );
        }
        await _filesDB.insertMultiple(batch);
        Bus.instance
            .fire(CollectionUpdatedEvent(dstCollectionID, batch, "copiedTo"));
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<(List<EnteFile>, List<EnteFile>)> _splitFilesToAddAndCopy(
    List<EnteFile> othersFile,
  ) async {
    final hashToUserFile =
        await _filesDB.getUserOwnedFilesWithSameHashForGivenListOfFiles(
      othersFile,
      _config.getUserID()!,
    );
    final List<EnteFile> filesToCopy = [];
    final List<EnteFile> filesToAdd = [];
    for (final EnteFile file in othersFile) {
      if (hashToUserFile.containsKey(file.hash ?? '')) {
        final userFile = hashToUserFile[file.hash]!;
        if (userFile.fileType == file.fileType) {
          filesToAdd.add(userFile);
        } else {
          filesToCopy.add(file);
        }
      } else {
        filesToCopy.add(file);
      }
    }
    return (filesToAdd, filesToCopy);
  }

  void _validateCopyInput(
    int destCollectionID,
    int srcCollectionID,
    List<EnteFile> files,
  ) {
    final dstCollection = _collectionIDToCollections[destCollectionID];
    final srcCollection = _collectionIDToCollections[srcCollectionID];
    if (dstCollection == null || !dstCollection.isOwner(_config.getUserID()!)) {
      throw ArgumentError(
        'Destination collection not found ${dstCollection == null} or not owned by user ',
      );
    }
    if (srcCollection == null) {
      throw ArgumentError('Source collection not found');
    }
    // verify that all fileIds belong to srcCollection and isn't owned by current user
    for (final f in files) {
      if (f.collectionID != srcCollectionID ||
          f.ownerID == _config.getUserID()) {
        _logger.warning(
          'file $f does not belong to srcCollection $srcCollection or is owned by current user ${f.ownerID}',
        );
        throw ArgumentError('');
      }
    }
  }

  Future<EnteFile> linkLocalFileToExistingUploadedFileInAnotherCollection(
    int destCollectionID, {
    required EnteFile localFileToUpload,
    required EnteFile existingUploadedFile,
  }) async {
    final params = <String, dynamic>{};
    params["collectionID"] = destCollectionID;
    params["files"] = [];
    final int uploadedFileID = existingUploadedFile.uploadedFileID!;

    // encrypt the fileKey with destination collection's key
    final fileKey = getFileKey(existingUploadedFile);
    final encryptedKeyData =
        CryptoUtil.encryptSync(fileKey, getCollectionKey(destCollectionID));

    localFileToUpload.encryptedKey =
        CryptoUtil.bin2base64(encryptedKeyData.encryptedData!);
    localFileToUpload.keyDecryptionNonce =
        CryptoUtil.bin2base64(encryptedKeyData.nonce!);

    params["files"].add(
      CollectionFileItem(
        uploadedFileID,
        localFileToUpload.encryptedKey!,
        localFileToUpload.keyDecryptionNonce!,
      ).toMap(),
    );

    try {
      await _enteDio.post(
        "/collections/add-files",
        data: params,
      );
      localFileToUpload.collectionID = destCollectionID;
      localFileToUpload.uploadedFileID = uploadedFileID;
      await _filesDB.insertMultiple([localFileToUpload]);
      return localFileToUpload;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restore(int toCollectionID, List<EnteFile> files) async {
    final params = <String, dynamic>{};
    params["collectionID"] = toCollectionID;
    final toCollectionKey = getCollectionKey(toCollectionID);
    final int ownerID = Configuration.instance.getUserID()!;
    final Set<String> existingLocalIDS =
        await FilesDB.instance.getExistingLocalFileIDs(ownerID);
    final batchedFiles = files.chunks(batchSize);
    for (final batch in batchedFiles) {
      params["files"] = [];
      for (final file in batch) {
        final fileKey = getFileKey(file);
        file.generatedID =
            null; // So that a new entry is created in the FilesDB
        file.collectionID = toCollectionID;
        // During restore, if trash file local ID is not present in currently
        // imported files, treat the file as deleted from device
        if (file.localID != null && !existingLocalIDS.contains(file.localID)) {
          file.localID = null;
        }
        final encryptedKeyData =
            CryptoUtil.encryptSync(fileKey, toCollectionKey);
        file.encryptedKey =
            CryptoUtil.bin2base64(encryptedKeyData.encryptedData!);
        file.keyDecryptionNonce =
            CryptoUtil.bin2base64(encryptedKeyData.nonce!);
        params["files"].add(
          CollectionFileItem(
            file.uploadedFileID!,
            file.encryptedKey!,
            file.keyDecryptionNonce!,
          ).toMap(),
        );
      }
      try {
        await _enteDio.post(
          "/collections/restore-files",
          data: params,
        );
        await _filesDB.insertMultiple(batch);
        await TrashDB.instance
            .delete(batch.map((e) => e.uploadedFileID!).toList());
        Bus.instance.fire(
          CollectionUpdatedEvent(toCollectionID, batch, "restore"),
        );
        Bus.instance.fire(FilesUpdatedEvent(batch, source: "restore"));
        // Remove imported local files which are imported but not uploaded.
        // This handles the case where local file was trashed -> imported again
        // but not uploaded automatically as it was trashed.
        final localIDs = batch
            .where((e) => e.localID != null)
            .map((e) => e.localID!)
            .toSet()
            .toList();
        if (localIDs.isNotEmpty) {
          await _filesDB.deleteUnSyncedLocalFiles(localIDs);
        }
        // Force reload home gallery to pull in the restored files
        Bus.instance.fire(ForceReloadHomeGalleryEvent("restoredFromTrash"));
      } catch (e, s) {
        _logger.severe("failed to restore files", e, s);
        rethrow;
      }
    }
  }

  Future<void> move(
    List<EnteFile> files, {
    required int toCollectionID,
    required int fromCollectionID,
  }) async {
    _validateMoveRequest(toCollectionID, fromCollectionID, files);
    files.removeWhere((element) => element.uploadedFileID == null);
    if (files.isEmpty) {
      _logger.info("nothing to move to collection");
      return;
    }
    final params = <String, dynamic>{};
    params["toCollectionID"] = toCollectionID;
    params["fromCollectionID"] = fromCollectionID;
    final batchedFiles = files.chunks(batchSize);
    for (final batch in batchedFiles) {
      params["files"] = [];
      for (final file in batch) {
        final fileKey = getFileKey(file);
        file.generatedID =
            null; // So that a new entry is created in the FilesDB
        file.collectionID = toCollectionID;
        final encryptedKeyData =
            CryptoUtil.encryptSync(fileKey, getCollectionKey(toCollectionID));
        file.encryptedKey =
            CryptoUtil.bin2base64(encryptedKeyData.encryptedData!);
        file.keyDecryptionNonce =
            CryptoUtil.bin2base64(encryptedKeyData.nonce!);
        params["files"].add(
          CollectionFileItem(
            file.uploadedFileID!,
            file.encryptedKey!,
            file.keyDecryptionNonce!,
          ).toMap(),
        );
      }
      await _enteDio.post(
        "/collections/move-files",
        data: params,
      );
    }

    // remove files from old collection
    await _filesDB.removeFromCollection(
      fromCollectionID,
      files.map((e) => e.uploadedFileID!).toList(),
    );
    Bus.instance.fire(
      CollectionUpdatedEvent(
        fromCollectionID,
        files,
        "moveFrom",
        type: EventType.deletedFromRemote,
      ),
    );
    // insert new files in the toCollection which are not part of the toCollection
    final existingUploadedIDs =
        await FilesDB.instance.getUploadedFileIDs(toCollectionID);
    files.removeWhere(
      (element) => existingUploadedIDs.contains(element.uploadedFileID),
    );
    await _filesDB.insertMultiple(files);
    Bus.instance.fire(
      CollectionUpdatedEvent(toCollectionID, files, "moveTo"),
    );
  }

  void _validateMoveRequest(
    int toCollectionID,
    int fromCollectionID,
    List<EnteFile> files,
  ) {
    final int userID = Configuration.instance.getUserID()!;
    if (toCollectionID == fromCollectionID) {
      throw AssertionError("Can't move to same album");
    }
    final Collection? toCollection = _collectionIDToCollections[toCollectionID];
    final Collection? fromCollection =
        _collectionIDToCollections[fromCollectionID];
    if (toCollection != null && !toCollection.isOwner(userID)) {
      throw AssertionError("Can't move to a collection you don't own");
    }
    if (fromCollection != null && !fromCollection.isOwner(userID)) {
      throw AssertionError("Can't move from a collection you don't own");
    }
    for (final file in files) {
      if (file.uploadedFileID == null) {
        throw AssertionError("Can only move uploaded memories");
      }
      if (file.collectionID != fromCollectionID) {
        throw AssertionError("All memories should belong to the same album");
      }
      if (file.ownerID != Configuration.instance.getUserID()) {
        throw AssertionError("Can only move memories uploaded by you");
      }
    }
  }

  Future<void> removeFromCollection(
    int collectionID,
    List<EnteFile> files,
  ) async {
    final params = <String, dynamic>{};
    params["collectionID"] = collectionID;
    final batchedFiles = files.chunks(batchSize);
    for (final batch in batchedFiles) {
      params["fileIDs"] = <int>[];
      for (final file in batch) {
        params["fileIDs"].add(file.uploadedFileID);
      }
      final resp = await _enteDio.post(
        "/collections/v3/remove-files",
        data: params,
      );
      if (resp.statusCode != 200) {
        throw Exception("Failed to remove files from collection");
      }

      await _filesDB.removeFromCollection(collectionID, params["fileIDs"]);
      Bus.instance
          .fire(CollectionUpdatedEvent(collectionID, batch, "removeFrom"));
      Bus.instance.fire(LocalPhotosUpdatedEvent(batch, source: "removeFrom"));
    }
    RemoteSyncService.instance.sync(silently: true).ignore();
  }

  Future<Collection> createAndCacheCollection(
    CreateRequest createRequest,
  ) async {
    final dynamic payload = createRequest.toJson();
    return _enteDio
        .post(
      "/collections",
      data: payload,
    )
        .then((response) async {
      final collectionData = response.data["collection"];
      final collection = await _fromRemoteCollection(collectionData);
      return _cacheLocalPathAndCollection(collection);
    });
  }

  @Deprecated("Use _cacheLocalPathAndCollection instead")
  Collection _cacheCollectionAttributes(Collection collection) {
    final String decryptedName = _getDecryptedCollectionName(collection);
    collection.setName(decryptedName);
    if (collection.canLinkToDevicePath(_config.getUserID()!)) {
      _localPathToCollectionID[_decryptCollectionPath(collection)] =
          collection.id;
    }
    _collectionIDToCollections[collection.id] = collection;
    return collection;
  }

  Collection _cacheLocalPathAndCollection(Collection collection) {
    assert(
      collection.decryptedName != null,
      "decryptedName should be already set",
    );
    if (collection.canLinkToDevicePath(_config.getUserID()!) &&
        (collection.decryptedPath ?? '').isNotEmpty) {
      _localPathToCollectionID[collection.decryptedPath!] = collection.id;
    }
    _collectionIDToCollections[collection.id] = collection;
    return collection;
  }

  String _decryptCollectionPath(Collection collection) {
    if (collection.decryptedPath != null &&
        collection.decryptedPath!.isNotEmpty) {
      debugPrint("Using cached decrypted path for collection ${collection.id}");
      return collection.decryptedPath!;
    } else {
      debugPrint(
        "Decrypting path for collection ${collection.id} from "
        "encryptedPath",
      );
    }
    final key = collection.attributes.version! >= 1
        ? getCollectionKey(collection.id)
        : _config.getKey();
    return utf8.decode(
      CryptoUtil.decryptSync(
        CryptoUtil.base642bin(collection.attributes.encryptedPath!),
        key!,
        CryptoUtil.base642bin(collection.attributes.pathDecryptionNonce!),
      ),
    );
  }

  bool hasSyncedCollections() {
    return _prefs.containsKey(_collectionsSyncTimeKey);
  }

  String _getDecryptedCollectionName(Collection collection) {
    if (collection.isDeleted) {
      return "Deleted Album";
    }
    if (collection.encryptedName != null &&
        collection.encryptedName!.isNotEmpty) {
      try {
        final collectionKey = _getAndCacheDecryptedKey(
          collection,
          source: "Name",
        );
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
    return collection.displayName;
  }

  Future _updateDB(List<Collection> collections, {int attempt = 1}) async {
    if (collections.isEmpty) {
      return;
    }
    try {
      await _db.insert(collections);
    } catch (e) {
      _logger.severe("Failed to update collections", e);
      if (attempt < kMaximumWriteAttempts) {
        return _updateDB(collections, attempt: ++attempt);
      } else {
        rethrow;
      }
    }
  }
}
