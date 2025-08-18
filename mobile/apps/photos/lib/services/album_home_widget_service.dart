import "dart:async";
import 'dart:convert';
import "dart:math";

import "package:collection/collection.dart";
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/services/home_widget_service.dart';
import 'package:photos/services/sync/local_sync_service.dart';
import "package:photos/ui/viewer/file/detail_page.dart";
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlbumHomeWidgetService {
  // Constants
  static const String SELECTED_ALBUMS_KEY = "selectedAlbumsHW";
  static const String ALBUMS_LAST_HASH_KEY = "albumsLastHash";
  static const String ANDROID_CLASS_NAME = "EnteAlbumsWidgetProvider";
  static const String IOS_CLASS_NAME = "EnteAlbumWidget";
  static const String ALBUMS_CHANGED_KEY = "albumsChanged.widget";
  static const String ALBUMS_STATUS_KEY = "albumsStatusKey.widget";
  static const String TOTAL_ALBUMS_KEY = "totalAlbums";
  static const int MAX_ALBUMS_LIMIT = 50;

  // Singleton pattern
  static final AlbumHomeWidgetService instance =
      AlbumHomeWidgetService._privateConstructor();
  AlbumHomeWidgetService._privateConstructor();

  // Properties
  final Logger _logger = Logger((AlbumHomeWidgetService).toString());
  SharedPreferences get _prefs => ServiceLocator.instance.prefs;

  // Public methods
  List<int>? getSelectedAlbumIds() {
    final selectedAlbums = _prefs.getStringList(SELECTED_ALBUMS_KEY);
    return selectedAlbums?.map((id) => int.tryParse(id) ?? 0).toList();
  }

  Future<void> updateSelectedAlbums(List<String> selectedAlbums) async {
    await _prefs.setStringList(SELECTED_ALBUMS_KEY, selectedAlbums);
    unawaited(_refreshOnSelection());
  }

  String? getAlbumsLastHash() {
    return _prefs.getString(ALBUMS_LAST_HASH_KEY);
  }

  Future<void> setAlbumsLastHash(String hash) async {
    await _prefs.setString(ALBUMS_LAST_HASH_KEY, hash);
  }

  Future<void> initAlbumHomeWidget(bool isBg) async {
    await HomeWidgetService.instance.computeLock.synchronized(() async {
      if (await _hasAnyBlockers(isBg)) {
        await clearWidget();
        return;
      }

      _logger.info("Initializing albums widget");

      final bool forceFetchNewAlbums = await _shouldUpdateWidgetCache();

      if (forceFetchNewAlbums) {
        await _updateAlbumsWidgetCache();
        await setSelectionChange(false);
        _logger.info("Force fetch new albums complete");
      } else {
        await _refreshAlbumsWidget();
        _logger.info("Refresh albums widget complete");
      }
    });
  }

  Future<void> clearWidget() async {
    if (getAlbumsStatus() == WidgetStatus.syncedEmpty) {
      return;
    }

    await setAlbumsLastHash("");
    await _setTotalAlbums(null);
    await updateAlbumsStatus(WidgetStatus.syncedEmpty);
    await _refreshWidget(message: "AlbumsHomeWidget cleared & updated");
  }

  bool? hasSelectionChanged() {
    return _prefs.getBool(ALBUMS_CHANGED_KEY);
  }

  Future<void> setSelectionChange(bool value) async {
    _logger.info("Updating albums changed flag to $value");
    await _prefs.setBool(ALBUMS_CHANGED_KEY, value);
  }

  WidgetStatus getAlbumsStatus() {
    return WidgetStatus.values.firstWhereOrNull(
          (v) => v.index == (_prefs.getInt(ALBUMS_STATUS_KEY) ?? 0),
        ) ??
        WidgetStatus.notSynced;
  }

  Future<void> updateAlbumsStatus(WidgetStatus value) async {
    await _prefs.setInt(ALBUMS_STATUS_KEY, value.index);
  }

  Future<int> countHomeWidgets() async {
    return await HomeWidgetService.instance.countHomeWidgets(
      ANDROID_CLASS_NAME,
      IOS_CLASS_NAME,
    );
  }

  Future<void> checkPendingAlbumsSync() async {
    if (await _hasAnyBlockers()) {
      await clearWidget();
      return;
    }

    _logger.info("Checking pending albums sync");
    if (await _shouldUpdateWidgetCache()) {
      await initAlbumHomeWidget(false);
    }
  }

  Future<void> _refreshOnSelection() async {
    final lastHash = getAlbumsLastHash();
    final selectedAlbumIds = await _getEffectiveSelectedAlbumIds(false);
    final currentHash = _calculateHash(selectedAlbumIds);
    if (lastHash != null && currentHash == lastHash) {
      _logger.info("No changes detected in albums");
      return;
    }

    await setSelectionChange(true);
    await initAlbumHomeWidget(false);
  }

  List<Collection> getAlbumsByIds(List<int> albumIds) {
    final albums = <Collection>[];

    for (final albumId in albumIds) {
      final collection = CollectionsService.instance.getCollectionByID(albumId);
      if (collection != null &&
          !collection.isDeleted &&
          !collection.isHidden()) {
        albums.add(collection);
      }
    }

    return albums;
  }

  Future<void> onLaunchFromWidget(
    int fileId,
    int collectionId,
    BuildContext context,
  ) async {
    final collection =
        CollectionsService.instance.getCollectionByID(collectionId);
    if (collection == null) {
      _logger.warning(
        "Cannot launch widget: collection with ID $collectionId not found",
      );
      return;
    }

    // First navigate to the collection page
    final thumbnail = await CollectionsService.instance.getCover(collection);
    routeToPage(
      context,
      CollectionPage(
        CollectionWithThumbnail(collection, thumbnail),
      ),
    ).ignore();
    final getAllFilesCollection =
        await FilesDB.instance.getAllFilesCollection(collection.id);

    // Then open the specific file
    final file = await FilesDB.instance.getFile(fileId);
    if (file == null) {
      _logger.warning("Cannot launch widget: file with ID $fileId not found");
      return;
    }

    routeToPage(
      context,
      DetailPage(
        DetailPageConfiguration(
          getAllFilesCollection,
          getAllFilesCollection.indexOf(file),
          "albumwidget",
        ),
      ),
      forceCustomPageRoute: true,
    ).ignore();
    await _refreshAlbumsWidget();
  }

  // Private methods
  String _calculateHash(List<int> albumIds) {
    String updationTimestamps = "";

    // TODO: This can be done in one shot by querying the database directly
    for (final albumId in albumIds) {
      final collection = CollectionsService.instance.getCollectionByID(albumId);
      if (collection != null) {
        updationTimestamps += "$albumId:${collection.updationTime.toString()}_";
      }
    }

    if (updationTimestamps.isEmpty) return "";

    final hash = md5
        .convert(utf8.encode(updationTimestamps))
        .toString()
        .substring(0, 10);
    return hash;
  }

  Future<bool> _hasAnyBlockers([bool isBg = false]) async {
    // Check if first import is completed
    final hasCompletedFirstImport =
        LocalSyncService.instance.hasCompletedFirstImport();
    if (!hasCompletedFirstImport) {
      return true;
    }

    // Check if selected albums exist
    final selectedAlbumIds = await _getEffectiveSelectedAlbumIds(isBg);
    final albums = getAlbumsByIds(selectedAlbumIds);

    if (albums.isEmpty) {
      _logger.info("Selected albums are empty or do not exist");
      return true;
    }

    return false;
  }

  Future<void> _refreshAlbumsWidget() async {
    // only refresh if widget was synced without issues
    if (await countHomeWidgets() == 0) return;
    await _refreshWidget(message: "Refreshing from existing album set");
  }

  Future<bool> _shouldUpdateWidgetCache() async {
    // Check if albums changed flag is set
    if (hasSelectionChanged() == true) {
      return true;
    }

    // Check if we have any albums selected
    final selectedAlbumIds = await _getEffectiveSelectedAlbumIds();
    if (selectedAlbumIds.isEmpty) {
      return false;
    }

    // Check if hash has changed
    final currentHash = _calculateHash(selectedAlbumIds);
    final lastHash = getAlbumsLastHash();

    if (currentHash == lastHash) {
      final saveStatus = getAlbumsStatus();
      switch (saveStatus) {
        case WidgetStatus.syncedPartially:
          return await countHomeWidgets() > 0;
        case WidgetStatus.syncedEmpty:
        case WidgetStatus.syncedAll:
          return false;
        default:
      }
    }

    return true;
  }

  Future<List<int>> _getEffectiveSelectedAlbumIds([bool isBg = false]) async {
    final selectedAlbumIds = getSelectedAlbumIds();

    // If no albums selected, use favorites as default
    if (selectedAlbumIds == null || selectedAlbumIds.isEmpty) {
      if (isBg) {
        await FavoritesService.instance.initFav();
      }
      final favoriteId =
          await FavoritesService.instance.getFavoriteCollectionID();
      if (favoriteId != null) {
        await updateSelectedAlbums([favoriteId.toString()]);
        return [favoriteId];
      }
    }

    return selectedAlbumIds ?? [];
  }

  Future<void> _refreshWidget({String? message}) async {
    await HomeWidgetService.instance.updateWidget(
      androidClass: ANDROID_CLASS_NAME,
      iOSClass: IOS_CLASS_NAME,
    );

    if (flagService.internalUser) {
      await Fluttertoast.showToast(
        msg: "[i][al] ${message ?? "AlbumsHomeWidget updated"}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    _logger.info("Home Widget updated: ${message ?? "standard update"}");
  }

  Future<Map<int, (String, Iterable<EnteFile>)>> _getAlbumsWithFiles() async {
    final selectedAlbumIds = await _getEffectiveSelectedAlbumIds();
    final albumsWithFiles = <int, (String, List<EnteFile>)>{};

    for (final albumId in selectedAlbumIds) {
      final collection = CollectionsService.instance.getCollectionByID(albumId);
      if (collection != null) {
        final files =
            await FilesDB.instance.getAllFilesCollection(collection.id);
        if (files.isNotEmpty) {
          albumsWithFiles[collection.id] =
              (collection.decryptedName ?? "Album", files);
        }
      }
    }

    return albumsWithFiles;
  }

  Future<void> _setTotalAlbums(int? total) async {
    await HomeWidgetService.instance.setData(TOTAL_ALBUMS_KEY, total);
  }

  Future<void> _updateAlbumsWidgetCache() async {
    final selectedAlbumIds = await _getEffectiveSelectedAlbumIds();
    final albumsWithFiles = await _getAlbumsWithFiles();

    if (albumsWithFiles.isEmpty) {
      await clearWidget();
      return;
    }

    final bool isWidgetPresent = await countHomeWidgets() > 0;

    final limit = isWidgetPresent ? MAX_ALBUMS_LIMIT : 5;
    final maxAttempts = limit * 10;

    int renderedCount = 0;
    int attemptsCount = 0;

    await updateAlbumsStatus(WidgetStatus.notSynced);

    final albumsWithFilesLength = albumsWithFiles.length;
    final albumsWithFilesEntries = albumsWithFiles.entries.toList();
    final random = Random();

    while (renderedCount < limit && attemptsCount < maxAttempts) {
      final randomEntry =
          albumsWithFilesEntries[random.nextInt(albumsWithFilesLength)];

      if (randomEntry.value.$2.isEmpty) continue;

      final randomAlbumFile = randomEntry.value.$2.elementAt(
        random.nextInt(randomEntry.value.$2.length),
      );
      final albumId = randomEntry.key;
      final albumName = randomEntry.value.$1;

      final renderResult = await HomeWidgetService.instance
          .renderFile(
        randomAlbumFile,
        "albums_widget_$renderedCount",
        albumName,
        albumId.toString(),
      )
          .catchError((e, stackTrace) {
        _logger.severe("Error rendering widget", e, stackTrace);
        return null;
      });

      if (renderResult != null) {
        // Check for blockers again before continuing
        if (await _hasAnyBlockers()) {
          await clearWidget();
          return;
        }

        await _setTotalAlbums(renderedCount);

        // Show update toast after first item is rendered
        if (renderedCount == 1) {
          await _refreshWidget(
            message: "First album fetched, updating widget",
          );
          await updateAlbumsStatus(WidgetStatus.syncedPartially);
        }

        renderedCount++;
      }

      attemptsCount++;
    }

    if (attemptsCount >= maxAttempts) {
      _logger.warning(
        "Hit max attempts $maxAttempts. Only rendered $renderedCount of limit $limit.",
      );
    }

    // Update the hash to track changes
    final hash = _calculateHash(selectedAlbumIds);
    await setAlbumsLastHash(hash);

    if (renderedCount == 0) {
      return;
    }

    if (isWidgetPresent) {
      await updateAlbumsStatus(WidgetStatus.syncedAll);
    }

    await _refreshWidget(
      message: "Switched to next albums set, total: $renderedCount",
    );
  }
}
