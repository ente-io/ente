import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:ente_events/event_bus.dart';
import 'package:ente_events/models/signed_in_event.dart';
import 'package:locker/events/collections_updated_event.dart';
import "package:locker/services/collections/collections_api_client.dart";
import "package:locker/services/collections/collections_db.dart";
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/trash/models/trash_item_request.dart';
import "package:locker/services/trash/trash_service.dart";
import "package:locker/utils/crypto_helper.dart";
import 'package:logging/logging.dart';

class CollectionService {
  CollectionService._privateConstructor();

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
  final _apiClient = CollectionApiClient.instance;

  Future<void> init() async {
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
    final updatedCollections = await CollectionApiClient.instance
        .getCollections(CollectionDB.instance.getSyncTime());
    if (updatedCollections.isEmpty) {
      _logger.info("No collections to sync.");
      return;
    }
    await CollectionDB.instance.updateCollections(updatedCollections);
    await CollectionDB.instance
        .setSyncTime(updatedCollections.last.updationTime);
    final List<Future> fileFutures = [];
    for (final collection in updatedCollections) {
      if (collection.isDeleted) {
        await CollectionDB.instance.deleteCollection(collection);
        continue;
      }
      final syncTime =
          CollectionDB.instance.getCollectionSyncTime(collection.id);
      fileFutures.add(
        CollectionApiClient.instance
            .getFiles(collection, syncTime)
            .then((diff) async {
          if (diff.updatedFiles.isNotEmpty) {
            await CollectionDB.instance.addFilesToCollection(
              collection,
              diff.updatedFiles,
            );
          }
          if (diff.deletedFiles.isNotEmpty) {
            await CollectionDB.instance.deleteFilesFromCollection(
              collection,
              diff.deletedFiles,
            );
          }
          await CollectionDB.instance
              .setCollectionSyncTime(collection.id, diff.latestUpdatedAtTime);
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
        CollectionDB.instance.getSyncTime() > 0;
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
    return CollectionDB.instance.getCollections();
  }

  Future<List<Collection>> getCollectionsForFile(EnteFile file) async {
    return CollectionDB.instance.getCollectionsForFile(file);
  }

  Future<List<EnteFile>> getFilesInCollection(Collection collection) async {
    try {
      final files =
          await CollectionDB.instance.getFilesInCollection(collection);
      return files;
    } catch (e) {
      _logger.severe(
        "Failed to fetch files for collection ${collection.name}: $e",
      );
      rethrow;
    }
  }

  Future<List<EnteFile>> getAllFiles() async {
    try {
      final allFiles = await CollectionDB.instance.getAllFiles();
      return allFiles;
    } catch (e) {
      _logger.severe("Failed to fetch all files: $e");
      rethrow;
    }
  }

  Future<void> addToCollection(Collection collection, EnteFile file) async {
    try {
      await _apiClient.addToCollection(collection, [file]);
      _logger.info("Added file ${file.title} to collection ${collection.name}");
      // Let sync update the local state
      await sync();
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
      await CollectionApiClient.instance.rename(
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
    return await CollectionDB.instance.getCollection(collectionID);
  }

  Future<Uint8List> getCollectionKey(int collectionID) async {
    final collection = await getCollection(collectionID);
    final collectionKey = CryptoHelper.instance.getCollectionKey(collection);
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
}
