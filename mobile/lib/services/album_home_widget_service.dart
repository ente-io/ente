import "dart:convert";

import "package:crypto/crypto.dart";
import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/favorites_service.dart";
import "package:photos/services/home_widget_service.dart";
import "package:photos/services/sync/local_sync_service.dart";
import "package:photos/ui/viewer/file/file_widget.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/navigation_util.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:synchronized/synchronized.dart";

class AlbumHomeWidgetService {
  final Logger _logger = Logger((AlbumHomeWidgetService).toString());

  AlbumHomeWidgetService._privateConstructor();

  static const _selectedAlbumsHWKey = "selectedAlbumsHW";
  static const _albumsLastHashKey = "albumsLastHash";
  static const _androidClass = "EnteAlbumsWidgetProvider";
  static const _iOSClass = "EnteAlbumWidget";

  static final AlbumHomeWidgetService instance =
      AlbumHomeWidgetService._privateConstructor();

  late final SharedPreferences _prefs;

  final _albumsForceRefreshLock = Lock();
  bool _hasSyncedAlbums = false;

  static const albumsChangedKey = "albumsChanged.widget";
  static const totalAlbums = "totalAlbums";

  init(SharedPreferences prefs) {
    _prefs = prefs;
  }

  Future<void> _forceAlbumsUpdate() async {
    await _lockAndLoadAlbum();
    await updateAlbumsChanged(false);
  }

  String? getAlbumsLastHash() {
    final albumsLastHash = _prefs.getString(_albumsLastHashKey);

    return albumsLastHash;
  }

  Future<void> setAlbumsLastHash(String hash) async {
    await _prefs.setString(_albumsLastHashKey, hash);
  }

  List<int>? getSelectedAlbums() {
    final selectedAlbums = _prefs.getStringList(_selectedAlbumsHWKey);

    return selectedAlbums?.map((e) => int.tryParse(e) ?? 0).toList();
  }

  Future<void> setSelectedAlbums(
    List<String> selectedAlbums,
  ) async {
    await _prefs.setStringList(_selectedAlbumsHWKey, selectedAlbums);
  }

  Future<int> countHomeWidgets() async {
    final installedWidgets =
        await HomeWidgetService.instance.getInstalledWidgets();

    final albumWidgets = installedWidgets
        .where(
          (element) =>
              element.androidClassName == _androidClass ||
              element.iOSKind == _iOSClass,
        )
        .toList();

    return albumWidgets.length;
  }

  Future<void> _albumsSync() async {
    final homeWidgetCount = await countHomeWidgets();
    if (homeWidgetCount == 0) {
      _logger.warning("no home widget active");
      return;
    }

    await _updateWidget(text: "refreshing from same set");
  }

  Future<bool> hasAnyBlockers() async {
    final hasCompletedFirstImport =
        LocalSyncService.instance.hasCompletedFirstImport();
    if (!hasCompletedFirstImport) {
      _logger.warning("first import not completed");
      return true;
    }

    final selectedAlbums = getSelectedAlbums();
    final albums = getAlbums(selectedAlbums ?? []);

    if ((selectedAlbums?.isNotEmpty ?? false) && albums.isEmpty) {
      _logger.warning("selected albums not found");
      return true;
    }

    return false;
  }

  Future<void> initAlbumsHW(bool? forceFetchNewAlbum) async {
    final result = await hasAnyBlockers();
    if (result) {
      await clearWidget();
      return;
    }

    await _albumsForceRefreshLock.synchronized(() async {
      HomeWidgetService.instance.setAppGroupID(iOSGroupIDAlbum);
      final result = await hasAnyBlockers();
      if (result) {
        return;
      }
      final isTotalEmpty = await _checkIfTotalEmpty();
      forceFetchNewAlbum ??= await getForceFetchCondition(isTotalEmpty);

      _logger.warning(
        "init albums hw: forceFetch: $forceFetchNewAlbum, isTotalEmpty: $isTotalEmpty",
      );

      if (forceFetchNewAlbum!) {
        await _forceAlbumsUpdate();
      } else if (!isTotalEmpty) {
        await _albumsSync();
      }
    });
  }

  Future<void> clearWidget() async {
    final isTotalEmpty = await _checkIfTotalEmpty();
    if (isTotalEmpty) {
      _logger.info(">>> Nothing to clear");
      return;
    }

    _logger.info("Clearing AlbumsHomeWidget");

    await _setTotal(null);
    _hasSyncedAlbums = false;

    await _updateWidget(text: "AlbumsHomeWidget cleared & updated");
  }

  Future<void> updateAlbumsChanged(bool value) async {
    _logger.info("Updating albums changed to $value");
    await _prefs.setBool(albumsChangedKey, value);
  }

  Future<bool> _checkIfTotalEmpty() async {
    HomeWidgetService.instance.setAppGroupID(iOSGroupIDAlbum);
    final total = await _getTotal();
    return total == 0 || total == null;
  }

  Future<bool> getForceFetchCondition(bool isTotalEmpty) async {
    final albumsChanged = _prefs.getBool(albumsChangedKey);
    if (albumsChanged == true) return true;

    final selectedAlbums = await getSelectedAlbumsIDs();
    if (selectedAlbums.isEmpty) {
      _logger.warning("No selected albums");
      return false;
    }

    final hash = getHash(selectedAlbums);
    final lastHash = getAlbumsLastHash();

    if (hash == lastHash) {
      _logger.warning("No changes detected");
      return false;
    }

    return true;
  }

  Future<void> checkPendingAlbumsSync() async {
    await Future.delayed(const Duration(seconds: 5), () {});

    final isTotalEmpty = await _checkIfTotalEmpty();
    final forceFetchNewAlbum = await getForceFetchCondition(isTotalEmpty);

    if (_hasSyncedAlbums && !forceFetchNewAlbum) {
      _logger.info(">>> Albums already synced");
      return;
    }
    await initAlbumsHW(forceFetchNewAlbum);
  }

  Future<Map<String, Iterable<EnteFile>>> _getAlbum() async {
    final selectedAlbums = await getSelectedAlbumsIDs();

    final albums = <String, List<EnteFile>>{};
    for (final selectedAlbum in selectedAlbums) {
      final collection =
          CollectionsService.instance.getCollectionByID(selectedAlbum);
      if (collection != null) {
        final files =
            await FilesDB.instance.getAllFilesCollection(collection.id);
        albums.addAll({
          collection.decryptedName ?? "Album": files,
        });
      }
    }

    if (albums.isEmpty) {
      _logger.warning("No albums found");
      return {};
    }

    return albums;
  }

  Future<void> _updateWidget({String? text}) async {
    await HomeWidgetService.instance.updateWidget(
      androidClass: _androidClass,
      iOSClass: _iOSClass,
    );
    if (flagService.internalUser) {
      await Fluttertoast.showToast(
        msg: "[i][al] ${text ?? "AlbumsHomeWidget updated"}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    _logger.info(">>> Home Widget updated, type: ${text ?? "normal"}");
  }

  String getHash(List<int> selectedAlbums) {
    final albums = <Collection>{};
    String currentDates = "";
    for (final selectedAlbum in selectedAlbums) {
      final collection =
          CollectionsService.instance.getCollectionByID(selectedAlbum);
      if (collection != null) {
        albums.add(collection);
        currentDates += "${collection.updationTime.toString()}_";
      }
    }

    final hash =
        md5.convert(utf8.encode(currentDates)).toString().substring(0, 10);
    return hash;
  }

  List<Collection> getAlbums(List<int> selectedAlbums) {
    final albums = <Collection>[];
    for (final selectedAlbum in selectedAlbums) {
      final collection =
          CollectionsService.instance.getCollectionByID(selectedAlbum);
      if (collection != null) {
        albums.add(collection);
      }
    }

    return albums;
  }

  Future<List<int>> getSelectedAlbumsIDs() async {
    final selectedAlbums = getSelectedAlbums();
    if (selectedAlbums == null || selectedAlbums.isEmpty) {
      final favoriteId =
          await FavoritesService.instance.getFavoriteCollectionID();
      if (favoriteId != null) {
        return [favoriteId];
      }
    }
    return selectedAlbums ?? [];
  }

  Future<void> albumsChanged() async {
    final lastHash = getAlbumsLastHash();

    final selectedAlbums = await getSelectedAlbumsIDs();
    final hash = getHash(selectedAlbums);

    if (selectedAlbums.isEmpty || hash == lastHash) {
      _logger.info(">>> No changes detected");
      return;
    }

    _logger.info(">>> Album changed, updating widget");
    await updateAlbumsChanged(true);
    await initAlbumsHW(true);
  }

  Future<int?> _getTotal() async {
    return HomeWidgetService.instance
        .getData<int>(totalAlbums, iOSGroupIDAlbum);
  }

  Future<void> _setTotal(int? total) async => await HomeWidgetService.instance
      .setData(totalAlbums, total, iOSGroupIDAlbum);

  Future<void> _lockAndLoadAlbum() async {
    final files = await _getAlbum();

    if (files.isEmpty) {
      _logger.warning("No files found, clearing everything");
      await clearWidget();
      return;
    }

    final total = await _getTotal();
    _logger.info(">>> Total albums before: $total");

    int index = 0;

    for (final i in files.entries) {
      for (final file in i.value) {
        final value = await HomeWidgetService.instance
            .renderFile(file, "albums_widget_$index", i.key, iOSGroupIDAlbum)
            .catchError(
          (e, sT) {
            _logger.severe("Error rendering widget", e, sT);
            return null;
          },
        );

        if (value != null) {
          final result = await hasAnyBlockers();
          if (result) {
            return;
          }
          if (index == 1) {
            await _updateWidget(
              text: "First albums fetched. updating widget",
            );
          }
          index++;
          await _setTotal(index);

          if (index >= 50) {
            _logger.warning(">>> Max albums limit reached");
            break;
          }
        }
      }

      if (index >= 50) {
        break;
      }
    }

    final selectedAlbums = await getSelectedAlbumsIDs();

    final hash = getHash(selectedAlbums);
    await setAlbumsLastHash(hash);

    if (index == 0) {
      return;
    }

    await _updateWidget(
      text: ">>> Switching to next albums set, total: $index",
    );
  }

  Future<void> onLaunchFromWidget(
    int generatedId,
    int collectionID,
    BuildContext context,
  ) async {
    _hasSyncedAlbums = true;
    await _albumsSync();

    final c = CollectionsService.instance.getCollectionByID(collectionID);
    if (c == null) {
      _logger.warning("onLaunchFromWidget: collection is null");
      return;
    }

    final thumbnail = await CollectionsService.instance.getCover(c);
    await routeToPage(
      context,
      CollectionPage(
        CollectionWithThumbnail(c, thumbnail),
      ),
    );
    final file = await FilesDB.instance.getFile(generatedId);
    if (file == null) {
      _logger.warning("onLaunchFromWidget: file is null");
      return;
    }
    // open generated id file preview
    await routeToPage(
      context,
      FileWidget(
        file,
        tagPrefix: "albumwidget",
      ),
    );
  }
}
