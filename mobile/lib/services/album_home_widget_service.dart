import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:logging/logging.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/home_widget_service.dart";
import "package:photos/services/sync/local_sync_service.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:synchronized/synchronized.dart";

class AlbumHomeWidgetService {
  final Logger _logger = Logger((AlbumHomeWidgetService).toString());

  AlbumHomeWidgetService._privateConstructor();

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

  Future<void> _albumsSync() async {
    final homeWidgetCount = await HomeWidgetService.instance.countHomeWidgets();
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

    // TODO: Check if any selected album doesn't exist
    // final areAlbumShown = albumsCacheService.showAnyAlbum;
    // if (!areAlbumShown) {
    //   _logger.warning("albums not enabled");
    //   return true;
    // }

    return false;
  }

  Future<void> initAlbumsHW(bool? forceFetchNewAlbum) async {
    final result = await hasAnyBlockers();
    if (result) {
      await clearWidget();
      return;
    }

    await _albumsForceRefreshLock.synchronized(() async {
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
    final total = await _getTotal();
    return total == 0 || total == null;
  }

  Future<bool> getForceFetchCondition(bool isTotalEmpty) async {
    final albumsChanged = _prefs.getBool(albumsChangedKey);
    if (albumsChanged == true) return true;

    // TODO: Get Album data i.e. List of Ente Files
    final cachedAlbum = []; // await albumsCacheService.getCachedAlbum();

    final forceFetchNewAlbum =
        isTotalEmpty && (cachedAlbum.isNotEmpty ?? false);
    return forceFetchNewAlbum;
  }

  Future<void> checkPendingAlbumsSync() async {
    await Future.delayed(const Duration(seconds: 5), () {});

    final isTotalEmpty = await _checkIfTotalEmpty();
    final forceFetchNewAlbum = await getForceFetchCondition(isTotalEmpty);

    if (_hasSyncedAlbums && !forceFetchNewAlbum) {
      _logger.info(">>> Albums already synced");
      return;
    }
    await HomeWidgetService.instance.initHomeWidget();
  }

  Future<Map<String, Iterable<EnteFile>>> _getAlbum() async {
    // TODO: Get Albums from the selected album and map them into title: files format

    // final albums = await albumsCacheService.getAlbum();
    // if (albums.isEmpty) {
    //   return {};
    // }

    // final files = Map.fromEntries(
    //   albums.map((m) {
    //     return MapEntry(m.title, m.albums.map((e) => e.file).toList());
    //   }),
    // );

    // return files;

    return {};
  }

  Future<void> _updateWidget({String? text}) async {
    await HomeWidgetService.instance.updateWidget(
      androidClass: "EnteAlbumsWidgetProvider",
      iOSClass: "EnteAlbumsWidget",
    );
    if (flagService.internalUser) {
      await Fluttertoast.showToast(
        msg: "[i] ${text ?? "AlbumsHomeWidget updated"}",
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

  Future<void> albumsChanged() async {
    // TODO: Get Albums and checks if size is changed
    final cachedAlbum = []; // await albumsCacheService.getCachedAlbum();
    final currentTotal = cachedAlbum.length ?? 0;

    final int total = await _getTotal() ?? 0;

    if (total == currentTotal && total == 0) {
      _logger.info(">>> Album not changed, doing nothing");
      return;
    }

    _logger.info(">>> Album changed, updating widget");
    await updateAlbumsChanged(true);
    await initAlbumsHW(true);
  }

  Future<int?> _getTotal() async {
    return HomeWidgetService.instance.getData<int>(totalAlbums);
  }

  Future<void> _setTotal(int? total) async =>
      await HomeWidgetService.instance.setData(totalAlbums, total);

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
            .renderFile(file, "albums_widget_$index", i.key)
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
          await _setTotal(index);
          if (index == 1) {
            await _updateWidget(
              text: "First albums fetched. updating widget",
            );
          }
          index++;

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

    if (index == 0) {
      return;
    }

    await _updateWidget(
      text: ">>> Switching to next albums set, total: $index",
    );
  }

  Future<void> onLaunchFromWidget(int generatedId, BuildContext context) async {
    _hasSyncedAlbums = true;
    await _albumsSync();

    // TODO: Open albums page for this album
  }
}
