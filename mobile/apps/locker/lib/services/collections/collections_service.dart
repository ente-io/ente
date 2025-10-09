import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:ente_events/event_bus.dart';
import 'package:ente_events/models/signed_in_event.dart';
import "package:ente_sharing/models/user.dart";
import "package:fast_base58/fast_base58.dart";
import "package:flutter/foundation.dart";
import 'package:locker/events/collections_updated_event.dart';
import "package:locker/services/collections/collections_api_client.dart";
import "package:locker/services/collections/collections_db.dart";
import 'package:locker/services/collections/models/collection.dart';
import "package:locker/services/collections/models/collection_items.dart";
import "package:locker/services/collections/models/public_url.dart";
import 'package:locker/services/configuration.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/trash/models/trash_item_request.dart';
import "package:locker/services/trash/trash_service.dart";
import "package:locker/utils/crypto_helper.dart";
import 'package:logging/logging.dart';

class CollectionService {
  static final CollectionService instance =
      CollectionService._privateConstructor();

  // Fixed set of suggested collection names
  static const Set<String> _suggestedCollectionNames = {
    'Personal',
    'Work',
    'Travel',
    'Family',
    'Projects',
    'School',
    'Music',
    'Books',
    'Events',
    'Holidays',
  };

  final _logger = Logger("CollectionService");

  late CollectionApiClient _apiClient;
  late CollectionDB _db;

  final _collectionIDToCollections = <int, Collection>{};

  CollectionService._privateConstructor();

  Future<void> init() async {
    _db = CollectionDB.instance;
    _apiClient = CollectionApiClient.instance;
    if (Configuration.instance.hasConfiguredAccount()) {
      await _init();
    } else {
      Bus.instance.on<SignedInEvent>().listen((event) {
        _logger.info("User signed in, starting initial sync.");
        _init();
      });
    }
  }

  Future<void> sync() async {
    final updatedCollections =
        await CollectionApiClient.instance.getCollections(_db.getSyncTime());
    if (updatedCollections.isEmpty) {
      _logger.info("No collections to sync.");
      return;
    }
    await _db.updateCollections(updatedCollections);
    // Update the cache with new/updated collections
    for (final collection in updatedCollections) {
      _collectionIDToCollections[collection.id] = collection;
    }
    await _db.setSyncTime(updatedCollections.last.updationTime);

    final List<Future> fileFutures = [];
    for (final collection in updatedCollections) {
      if (collection.isDeleted) {
        await _db.deleteCollection(collection);
        _collectionIDToCollections.remove(collection.id);
        continue;
      }
      final syncTime = _db.getCollectionSyncTime(collection.id);
      fileFutures.add(
        _apiClient.getFiles(collection, syncTime).then((diff) async {
          if (diff.updatedFiles.isNotEmpty) {
            await _db.addFilesToCollection(
              collection,
              diff.updatedFiles,
            );
          }
          if (diff.deletedFiles.isNotEmpty) {
            await _db.deleteFilesFromCollection(
              collection,
              diff.deletedFiles,
            );
          }
          await _db.setCollectionSyncTime(
            collection.id,
            diff.latestUpdatedAtTime,
          );
        }).catchError((e) {
          _logger.warning(
            "Failed to fetch files for collection ${collection.id}: $e",
          );
        }),
      );
    }
    await Future.wait(fileFutures);
    if (updatedCollections.isNotEmpty) {
      Bus.instance.fire(CollectionsUpdatedEvent());
    }
  }

  bool hasCompletedFirstSync() {
    return Configuration.instance.hasConfiguredAccount() &&
        _db.getSyncTime() > 0;
  }

  Future<Collection> createCollection(
    String name, {
    CollectionType type = CollectionType.folder,
  }) async {
    try {
      final collection = await _apiClient.create(name, type);
      _logger.info("Created collection: ${collection.name}");
      // Let sync update the local state
      await sync();
      return collection;
    } catch (e) {
      _logger.severe("Failed to create collection: $e");
      rethrow;
    }
  }

  Future<List<Collection>> getCollections() async {
    return _db.getCollections();
  }

  Future<SharedCollections> getSharedCollections() async {
    final List<Collection> outgoing = [];
    final List<Collection> incoming = [];
    final List<Collection> quickLinks = [];

    final List<Collection> collections = await getCollections();

    for (final c in collections) {
      if (c.owner.id == Configuration.instance.getUserID()) {
        if (c.hasSharees || c.hasLink && !c.isQuickLinkCollection()) {
          outgoing.add(c);
        } else if (c.isQuickLinkCollection()) {
          quickLinks.add(c);
        }
      } else {
        incoming.add(c);
      }
    }
    return SharedCollections(outgoing, incoming, quickLinks);
  }

  Future<List<Collection>> getCollectionsForFile(EnteFile file) async {
    return _db.getCollectionsForFile(file);
  }

  Future<List<EnteFile>> getFilesInCollection(Collection collection) async {
    try {
      final files = await _db.getFilesInCollection(collection);
      return files;
    } catch (e) {
      _logger.severe(
        "Failed to fetch files for collection ${collection.name}: $e",
      );
      rethrow;
    }
  }

  Future<int> getFileCount(Collection collection) async {
    final files = await getFilesInCollection(collection);
    return files.length;
  }

  Future<int> getFileSize(EnteFile file) async {
    int fileSize;
    if (file.fileSize != null) {
      fileSize = file.fileSize!;
    } else {
      // TODO: Need to write the code to getFile from server
      // fileSize = await getFile(file).then((f) => f!.length());
      fileSize = 0;
    }
    return fileSize;
  }

  Future<List<EnteFile>> getAllFiles() async {
    try {
      final allFiles = await _db.getAllFiles();
      return allFiles;
    } catch (e) {
      _logger.severe("Failed to fetch all files: $e");
      rethrow;
    }
  }

  /// Adds a file to a collection. By default this triggers a full sync to
  /// update local state. Set [runSync] to false to delay syncing (useful when
  /// adding the same file to multiple collections during an upload).
  Future<void> addToCollection(
    Collection collection,
    EnteFile file, {
    bool runSync = true,
  }) async {
    try {
      await _apiClient.addToCollection(collection, [file]);
      _logger.info("Added file ${file.title} to collection ${collection.name}");
      if (runSync) {
        // Let sync update the local state
        await sync();
      }
    } catch (e) {
      _logger.severe("Failed to add file to collection: $e");
      rethrow;
    }
  }

  Future<void> trashFile(EnteFile file, Collection collection) async {
    try {
      final List<TrashRequest> requests = [];
      requests.add(TrashRequest(file.uploadedFileID!, collection.id));
      await _apiClient.trash(requests);
      // Let sync update the local state
      await sync();
      await TrashService.instance.syncTrash();
    } catch (e) {
      _logger.severe("Failed to remove file from collections: $e");
      rethrow;
    }
  }

  Future<void> rename(Collection collection, String newName) async {
    try {
      await _apiClient.rename(
        collection,
        newName,
      );
      _logger.info("Renamed collection ${collection.name} to $newName");
      // Let sync update the local state
      await sync();
    } catch (e, s) {
      _logger.warning("failed to rename collection", e, s);
      rethrow;
    }
  }

  Future<Collection> getOrCreateUncategorizedCollection() async {
    final collections = await getCollections();
    for (final collection in collections) {
      if (collection.type == CollectionType.uncategorized) {
        return collection;
      }
    }
    _logger.info("No collections found, creating uncategorized collection.");
    return await createCollection(
      "Uncategorized",
      type: CollectionType.uncategorized,
    );
  }

  Future<void> _init() async {
    // ignore: unawaited_futures
    sync().then((_) {
      setupDefaultCollections();
    }).catchError((error) {
      _logger.severe("Failed to initialize collections: $error");
    });
    final collections = await _db.getCollections();
    for (final collection in collections) {
      _collectionIDToCollections[collection.id] = collection;
    }
  }

  Future<Collection> _getOrCreateImportantCollection() async {
    final collections = await getCollections();
    for (final collection in collections) {
      if (collection.type == CollectionType.favorites) {
        return collection;
      }
    }
    _logger.info("No collections found, creating important collection.");
    return await createCollection("Important", type: CollectionType.favorites);
  }

  Future<void> move(EnteFile file, Collection from, Collection to) async {
    try {
      await _apiClient.move(file, from, to);
      _logger.info("Moved file ${file.title} from ${from.name} to ${to.name}");
      // Let sync update the local state
      await sync();
    } catch (e) {
      _logger.severe("Failed to move file: $e");
      rethrow;
    }
  }

  Future<void> trashCollection(Collection collection) async {
    try {
      await _apiClient.trashCollection(collection);
      _logger.info("Trashed collection: ${collection.name}");
      // Let sync update the local state
      await sync();
    } catch (e) {
      _logger.severe("Failed to trash collection: $e");
      rethrow;
    }
  }

  Future<void> setupDefaultCollections() async {
    try {
      _logger.info("Setting up default collections...");

      // Create uncategorized collection if it doesn't exist
      await getOrCreateUncategorizedCollection();

      // Create important (favorites) collection if it doesn't exist
      await _getOrCreateImportantCollection();

      // Create Documents collection if it doesn't exist
      await _getOrCreateDocumentsCollection();

      _logger.info("Default collections setup completed.");
    } catch (e, s) {
      _logger.severe("Failed to setup default collections", e, s);
    }
  }

  Future<Collection> _getOrCreateDocumentsCollection() async {
    final collections = await getCollections();
    for (final collection in collections) {
      if (collection.type == CollectionType.folder &&
          collection.name == "Documents") {
        return collection;
      }
    }
    _logger
        .info("No Documents collection found, creating Documents collection.");
    return createCollection("Documents", type: CollectionType.folder);
  }

  /// Returns one random collection name that doesn't already exist
  /// If all names are used, returns "Documents"
  Future<String> getRandomUnusedCollectionName() async {
    try {
      final existingCollections = await getCollections();
      final existingNames = existingCollections
          .map((collection) => collection.name?.toLowerCase())
          .where((name) => name != null)
          .toSet();

      final availableNames = _suggestedCollectionNames
          .where((name) => !existingNames.contains(name.toLowerCase()))
          .toList();

      if (availableNames.isEmpty) {
        _logger.info(
          "All suggested collection names are used, returning 'Documents'",
        );
        return "Documents";
      }

      final random = Random();
      final randomName = availableNames[random.nextInt(availableNames.length)];
      _logger.info("Selected random unused collection name: $randomName");
      return randomName;
    } catch (e) {
      _logger.severe("Failed to get random unused collection name: $e");
      return "Documents";
    }
  }

  Future<Collection> getCollection(int collectionID) async {
    if (_collectionIDToCollections.containsKey(collectionID)) {
      return _collectionIDToCollections[collectionID]!;
    }
    final collection = await _db.getCollection(collectionID);
    _collectionIDToCollections[collectionID] = collection;
    return collection;
  }

  Uint8List getCollectionKey(int collectionID) {
    final collection = _collectionIDToCollections[collectionID];
    final collectionKey = CryptoHelper.instance.getCollectionKey(collection!);
    return collectionKey;
  }

  Future<Uint8List> getFileKey(EnteFile file) async {
    try {
      final collection = await getCollection(file.collectionID!);
      final collectionKey = CryptoHelper.instance.getCollectionKey(collection);

      final fileKey = CryptoHelper.instance.getFileKey(
        file.encryptedKey!,
        file.keyDecryptionNonce!,
        collectionKey,
      );

      _logger.info("Successfully decrypted file key for file ${file.title}");
      return fileKey;
    } catch (e) {
      _logger.severe("Failed to get file key: $e");
      rethrow;
    }
  }

  // getActiveCollections returns list of collections which are not deleted yet
  List<Collection> getActiveCollections() {
    return _collectionIDToCollections.values
        .toList()
        .where((element) => !element.isDeleted)
        .toList();
  }

  /// Returns Contacts(Users) that are relevant to the account owner.
  /// Note: "User" refers to the account owner in the points below.
  /// This includes:
  /// 	- Collaborators and viewers of collections owned by user
  ///   - Owners of collections shared to user.
  ///   - All collaborators of collections in which user is a collaborator or
  ///     a viewer.
  List<User> getRelevantContacts() {
    final List<User> relevantUsers = [];
    final existingEmails = <String>{};
    final int ownerID = Configuration.instance.getUserID()!;
    final String ownerEmail = Configuration.instance.getEmail()!;
    existingEmails.add(ownerEmail);

    for (final c in getActiveCollections()) {
      // Add collaborators and viewers of collections owned by user
      if (c.owner.id == ownerID) {
        for (final User u in c.sharees) {
          if (u.id != null && u.email.isNotEmpty) {
            if (!existingEmails.contains(u.email)) {
              relevantUsers.add(u);
              existingEmails.add(u.email);
            }
          }
        }
      } else if (c.owner.id != null && c.owner.email.isNotEmpty) {
        // Add owners of collections shared with user
        if (!existingEmails.contains(c.owner.email)) {
          relevantUsers.add(c.owner);
          existingEmails.add(c.owner.email);
        }
        // Add collaborators of collections shared with user where user is a
        // viewer or a collaborator
        for (final User u in c.sharees) {
          if (u.id != null &&
              u.email.isNotEmpty &&
              u.email == ownerEmail &&
              (u.isCollaborator || u.isViewer)) {
            for (final User u in c.sharees) {
              if (u.id != null && u.email.isNotEmpty && u.isCollaborator) {
                if (!existingEmails.contains(u.email)) {
                  relevantUsers.add(u);
                  existingEmails.add(u.email);
                }
              }
            }
            break;
          }
        }
      }
    }

    return relevantUsers;
  }

  String getPublicUrl(Collection c) {
    final PublicURL url = c.publicURLs.firstOrNull!;
    final Uri publicUrl = Uri.parse(url.url);

    final cKey = getCollectionKey(c.id);
    final String collectionKey = Base58Encode(cKey);
    final String urlValue = "${publicUrl.toString()}#$collectionKey";
    return urlValue;
  }

  void clearCache() {
    _collectionIDToCollections.clear();
  }

  // Methods for managing collection cache
  void updateCollectionCache(Collection collection) {
    _collectionIDToCollections[collection.id] = collection;
  }

  void removeFromCache(int collectionId) {
    _collectionIDToCollections.remove(collectionId);
  }

  Collection? getFromCache(int collectionId) {
    return _collectionIDToCollections[collectionId];
  }
}
