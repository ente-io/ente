import "package:flutter/material.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/home_widget_service.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/services/sync/local_sync_service.dart";
import "package:photos/ui/viewer/file/file_widget.dart";
import "package:photos/utils/navigation_util.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:synchronized/synchronized.dart";

class PeopleHomeWidgetService {
  final Logger _logger = Logger((PeopleHomeWidgetService).toString());

  PeopleHomeWidgetService._privateConstructor();

  static const _selectedPeopleHWKey = "selectedPeopleHW";
  static const _androidClass = "EntePeopleWidgetProvider";
  static const _iOSClass = "EntePeopleWidget";

  static final PeopleHomeWidgetService instance =
      PeopleHomeWidgetService._privateConstructor();

  late final SharedPreferences _prefs;

  final _peopleForceRefreshLock = Lock();
  bool _hasSyncedPeople = false;

  static const peopleChangedKey = "peopleChanged.widget";
  static const totalPeople = "totalPeople";

  init(SharedPreferences prefs) {
    _prefs = prefs;
  }

  Future<void> _forcePeopleUpdate() async {
    await _lockAndLoadPeople();
    await updatePeopleChanged(false);
  }

  List<String>? getSelectedPeople() {
    final selectedAlbums = _prefs.getStringList(_selectedPeopleHWKey);
    return selectedAlbums;
  }

  Future<void> setSelectedPeople(
    List<String> selectedAlbums,
  ) async {
    final oldValue = getSelectedPeople();
    await _prefs.setStringList(_selectedPeopleHWKey, selectedAlbums);
    if (oldValue != null) {
      final set1 = oldValue.toSet();
      final set2 = selectedAlbums.toSet();

      if (set1.containsAll(set2) && set2.containsAll(set1)) {
        _logger.info("People not changed, doing nothing");
        return;
      }
    }
    _logger.info("People changed, updating widget");
    await updatePeopleChanged(true);
  }

  Future<int> countHomeWidgets() async {
    final installedWidgets =
        await HomeWidgetService.instance.getInstalledWidgets();

    final peopleWidgets = installedWidgets
        .where(
          (element) =>
              element.androidClassName == _androidClass ||
              element.iOSKind == _iOSClass,
        )
        .toList();

    return peopleWidgets.length;
  }

  Future<void> _peopleSync() async {
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

    if (!flagService.hasGrantedMLConsent) {
      _logger.warning("ML consent not granted");
      return true;
    }

    final peopleIds = getSelectedPeople();
    try {
      for (final id in peopleIds ?? []) {
        final person = await PersonService.instance.getPerson(id);
        if (person == null) {
          _logger.warning("Person not found for id: $id");
          return true;
        }
      }
    } catch (e) {
      _logger.warning("Error looking people:", e);
      return true;
    }

    // TODO: If  peopleIds are null then check if SearchFilter contains atleast one

    return false;
  }

  Future<void> initPeopleHW(bool? forceFetchNewPeople) async {
    final result = await hasAnyBlockers();
    if (result) {
      await clearWidget();
      return;
    }

    await _peopleForceRefreshLock.synchronized(() async {
      final result = await hasAnyBlockers();
      if (result) {
        return;
      }
      final isTotalEmpty = await _checkIfTotalEmpty();
      forceFetchNewPeople ??= await getForceFetchCondition(isTotalEmpty);

      _logger.warning(
        "init people hw: forceFetch: $forceFetchNewPeople, isTotalEmpty: $isTotalEmpty",
      );

      if (forceFetchNewPeople!) {
        await _forcePeopleUpdate();
      } else if (!isTotalEmpty) {
        await _peopleSync();
      }
    });
  }

  Future<void> clearWidget() async {
    final isTotalEmpty = await _checkIfTotalEmpty();
    if (isTotalEmpty) {
      _logger.info(">>> Nothing to clear");
      return;
    }

    _logger.info("Clearing PeopleHomeWidget");

    await _setTotal(null);
    _hasSyncedPeople = false;

    await _updateWidget(text: "PeopleHomeWidget cleared & updated");
  }

  Future<void> updatePeopleChanged(bool value) async {
    _logger.info("Updating people changed to $value");
    await _prefs.setBool(peopleChangedKey, value);
  }

  Future<bool> _checkIfTotalEmpty() async {
    final total = await _getTotal();
    return total == 0 || total == null;
  }

  Future<bool> getForceFetchCondition(bool isTotalEmpty) async {
    final peopleChanged = _prefs.getBool(peopleChangedKey);
    return peopleChanged ?? true;
  }

  Future<void> checkPendingPeopleSync({bool addDelay = true}) async {
    if (addDelay) await Future.delayed(const Duration(seconds: 5), () {});

    final isTotalEmpty = await _checkIfTotalEmpty();
    final forceFetchNewPeople = await getForceFetchCondition(isTotalEmpty);

    if (_hasSyncedPeople && !forceFetchNewPeople) {
      _logger.info(">>> People already synced");
      return;
    }
    await HomeWidgetService.instance.initHomeWidget();
  }

  Future<Map<String, (String, Iterable<EnteFile>)>> _getPeople() async {
    final peopleIds = getSelectedPeople();
    final Map<String, (String, Iterable<EnteFile>)> files = {};
    for (final id in peopleIds ?? []) {
      final person = await PersonService.instance.getPerson(id);
      if (person == null) {
        _logger.warning("Person not found for id: $id");
        continue;
      }
      final clusterFiles =
          await SearchService.instance.getClusterFilesForPersonID(id);
      files[id] = (
        person.data.name,
        clusterFiles.entries.expand((e) => e.value).toList()
      );
    }

    return files;
  }

  Future<void> _updateWidget({String? text}) async {
    await HomeWidgetService.instance.updateWidget(
      androidClass: _androidClass,
      iOSClass: _iOSClass,
    );
    if (flagService.internalUser) {
      await Fluttertoast.showToast(
        msg: "[i][pe] ${text ?? "PeopleHomeWidget updated"}",
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

  Future<int?> _getTotal() async {
    return HomeWidgetService.instance.getData<int>(totalPeople);
  }

  Future<void> _setTotal(int? total) async =>
      await HomeWidgetService.instance.setData(totalPeople, total);

  Future<void> _lockAndLoadPeople() async {
    final files = await _getPeople();

    if (files.isEmpty) {
      _logger.warning("No files found, clearing everything");
      await clearWidget();
      return;
    }

    final total = await _getTotal();
    _logger.info(">>> Total people before: $total");

    int index = 0;

    for (final i in files.entries) {
      for (final file in i.value.$2) {
        final value = await HomeWidgetService.instance
            .renderFile(
          file,
          "people_widget_$index",
          i.value.$1,
          i.key,
        )
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
              text: "First people fetched. updating widget",
            );
          }
          index++;

          if (index >= 50) {
            _logger.warning(">>> Max people limit reached");
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
      text: ">>> Switching to next people set, total: $index",
    );
  }

  Future<void> onLaunchFromWidget(int generatedId, BuildContext context) async {
    _hasSyncedPeople = true;
    await _peopleSync();

    // routeToPage(
    //   context,
    //   SearchResultPage(searchResult),
    // );

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
        tagPrefix: "peoplewidget",
      ),
    );
  }
}
