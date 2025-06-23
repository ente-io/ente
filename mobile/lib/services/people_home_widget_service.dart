import "dart:math";

import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_constants.dart";
import "package:photos/models/search/search_types.dart";
import 'package:photos/service_locator.dart';
import 'package:photos/services/home_widget_service.dart';
import 'package:photos/services/machine_learning/face_ml/person/person_service.dart';
import 'package:photos/services/search_service.dart';
import 'package:photos/services/sync/local_sync_service.dart';
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import 'package:photos/utils/navigation_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

class PeopleHomeWidgetService {
  // Constants
  static const String SELECTED_PEOPLE_KEY = "selectedPeopleHW";
  static const String PEOPLE_LAST_HASH_KEY = "peopleLastHash";
  static const String ANDROID_CLASS_NAME = "EntePeopleWidgetProvider";
  static const String IOS_CLASS_NAME = "EntePeopleWidget";
  static const String PEOPLE_STATUS_KEY = "peopleStatusKey.widget";
  static const String PEOPLE_CHANGED_KEY = "peopleChanged.widget";
  static const String TOTAL_PEOPLE_KEY = "totalPeople";
  static const int MAX_PEOPLE_LIMIT = 50;

  // Singleton pattern
  static final PeopleHomeWidgetService instance =
      PeopleHomeWidgetService._privateConstructor();
  PeopleHomeWidgetService._privateConstructor();

  // Properties
  final Logger _logger = Logger((PeopleHomeWidgetService).toString());
  late final SharedPreferences _prefs;
  final _peopleForceRefreshLock = Lock();
  final _lock2 = Lock();
  bool _hasSyncedPeople = false;

  // Initialization
  void init(SharedPreferences prefs) {
    _prefs = prefs;
  }

  // Public methods
  List<String>? getSelectedPeople() {
    return _prefs.getStringList(SELECTED_PEOPLE_KEY);
  }

  Future<void> setSelectedPeople(List<String> selectedPeople) async {
    final previousSelection = getSelectedPeople();
    await _prefs.setStringList(SELECTED_PEOPLE_KEY, selectedPeople);

    if (previousSelection != null) {
      final oldSet = previousSelection.toSet();
      final newSet = selectedPeople.toSet();

      if (oldSet.containsAll(newSet) && newSet.containsAll(oldSet)) {
        _logger.info("People selection unchanged, no update needed");
        return;
      }
    }

    _logger.info("People selection changed, updating widget");
    await updatePeopleChanged(true);
  }

  String? getPeopleLastHash() {
    return _prefs.getString(PEOPLE_LAST_HASH_KEY);
  }

  Future<void> setPeopleLastHash(String hash) async {
    await _prefs.setString(PEOPLE_LAST_HASH_KEY, hash);
  }

  Future<int> countHomeWidgets() async {
    return await HomeWidgetService.instance.countHomeWidgets(
      ANDROID_CLASS_NAME,
      IOS_CLASS_NAME,
    );
  }

  Future<void> initHomeWidget(bool? forceFetchNewPeople) async {
    if (await _hasAnyBlockers()) {
      await clearWidget();
      return;
    }

    await _peopleForceRefreshLock.synchronized(() async {
      if (await _hasAnyBlockers()) {
        return;
      }

      final isPeopleEmpty = await _isWidgetEmpty();
      forceFetchNewPeople ??= await _shouldForceFetchPeople(isPeopleEmpty);

      _logger.warning(
        "Initializing people widget: forceFetch: $forceFetchNewPeople, isPeopleEmpty: $isPeopleEmpty",
      );

      if (forceFetchNewPeople!) {
        await _forcePeopleUpdate();
      } else if (!isPeopleEmpty) {
        await _syncExistingPeople();
      }
    });
  }

  Future<void> clearWidget() async {
    if (await _isWidgetEmpty()) {
      _logger.info("Widget already empty, nothing to clear");
      return;
    }

    _logger.info("Clearing PeopleHomeWidget");
    await _setTotalPeople(null);
    _hasSyncedPeople = false;
    await updatePeopleStatus(WidgetStatus.syncedEmpty);
    await setPeopleLastHash("");
    await _refreshWidget(message: "PeopleHomeWidget cleared & updated");
  }

  WidgetStatus getPeopleStatus() {
    return WidgetStatus.values.firstWhereOrNull(
          (v) => v.index == (_prefs.getInt(PEOPLE_STATUS_KEY) ?? 0),
        ) ??
        WidgetStatus.notSynced;
  }

  Future<void> updatePeopleStatus(WidgetStatus value) async {
    await _prefs.setInt(PEOPLE_STATUS_KEY, value.index);
  }

  Future<void> updatePeopleChanged(bool value) async {
    _logger.info("Updating people changed flag to $value");
    await _prefs.setBool(PEOPLE_CHANGED_KEY, value);
  }

  Future<void> checkPendingPeopleSync({bool addDelay = true}) async {
    if (addDelay) {
      await Future.delayed(const Duration(seconds: 5));
    }

    final isPeopleEmpty = await _isWidgetEmpty();
    final needsForceFetch = await _shouldForceFetchPeople(isPeopleEmpty);

    if (_hasSyncedPeople && !needsForceFetch) {
      _logger.info("People already synced, no action needed");
      return;
    }

    await HomeWidgetService.instance.initHomeWidget();
  }

  Future<void> checkPeopleChanged() async {
    final havePeopleChanged = await _lock2.synchronized(() async {
      final peopleIds = await _getEffectiveSelectedPeopleIds();
      final currentHash = await _calculateHash(peopleIds);
      final lastHash = getPeopleLastHash();
      if (peopleIds.isEmpty || currentHash == lastHash) {
        return false;
      }
      return true;
    });

    await updatePeopleChanged(havePeopleChanged);
    if (!havePeopleChanged) {
      _logger.info("No changes detected in people, skipping update");
      return;
    }
    await initHomeWidget(true);
  }

  Future<void> onLaunchFromWidget(
    int fileId,
    String personId,
    BuildContext context,
  ) async {
    _hasSyncedPeople = true;
    await _syncExistingPeople();

    final file = await FilesDB.instance.getFile(fileId);
    if (file == null) {
      _logger.warning("Cannot launch widget: file with ID $fileId not found");
      return;
    }

    final person = await PersonService.instance.getPerson(personId);
    if (person == null) {
      _logger
          .warning("Cannot launch widget: person with ID $personId not found");
      return;
    }

    routeToPage(
      context,
      PeoplePage(
        person: person,
        searchResult: null,
      ),
      forceCustomPageRoute: true,
    ).ignore();

    final clusterFiles =
        await SearchService.instance.getClusterFilesForPersonID(
      personId,
    );
    final files = clusterFiles.entries.expand((e) => e.value).toList();

    await routeToPage(
      context,
      DetailPage(
        DetailPageConfiguration(
          files,
          files.indexOf(file),
          "peoplewidget",
        ),
      ),
      forceCustomPageRoute: true,
    );
  }

  // Private methods
  Future<void> _forcePeopleUpdate() async {
    await _loadAndRenderPeople();
    await updatePeopleChanged(false);
  }

  Future<String> _calculateHash(List<String> peopleIds) async {
    return await entityService.getHashForIds(peopleIds);
  }

  Future<bool> _hasAnyBlockers() async {
    // Check if first import is completed
    final hasCompletedFirstImport =
        LocalSyncService.instance.hasCompletedFirstImport();
    if (!hasCompletedFirstImport) {
      _logger.warning("First import not completed");
      return true;
    }

    // Check ML consent
    if (!flagService.hasGrantedMLConsent) {
      _logger.warning("ML consent not granted");
      return true;
    }

    // Check if selected people exist
    final peopleIds = await _getEffectiveSelectedPeopleIds();
    try {
      for (final id in peopleIds) {
        final person = await PersonService.instance.getPerson(id);
        if (person == null) {
          _logger.warning("Person not found for id: $id");
          return true;
        }
      }
    } catch (e) {
      _logger.warning("Error looking up people: $e");
      return true;
    }

    return false;
  }

  Future<void> _syncExistingPeople() async {
    final homeWidgetCount = await countHomeWidgets();
    if (homeWidgetCount == 0) {
      _logger.warning("No active home widgets found");
      return;
    }

    await _refreshWidget(message: "Refreshing from existing people set");
  }

  Future<bool> _isWidgetEmpty() async {
    final totalPeople = await _getTotalPeople();
    return totalPeople == 0 || totalPeople == null;
  }

  Future<bool> _shouldForceFetchPeople(bool isPeopleEmpty) async {
    final peopleChanged = _prefs.getBool(PEOPLE_CHANGED_KEY);
    if (peopleChanged ?? true) {
      return true;
    }

    final peopleStatus = getPeopleStatus();
    switch (peopleStatus) {
      case WidgetStatus.notSynced:
        return true;
      case WidgetStatus.syncedPartially:
        return await countHomeWidgets() > 0;
      case WidgetStatus.syncedEmpty:
      case WidgetStatus.syncedAll:
        return false;
    }
  }

  Future<List<String>> _getEffectiveSelectedPeopleIds() async {
    var peopleIds = getSelectedPeople();

    if (peopleIds == null || peopleIds.isEmpty) {
      // Search Filter with face and pick top two faces
      final searchFilter = await SectionType.face.getData(null).then(
            (value) => (value as List<GenericSearchResult>).where(
              (element) => (element.params[kPersonParamID] as String?) != null,
            ),
          );

      if (searchFilter.isNotEmpty) {
        peopleIds = searchFilter
            .take(2)
            .map((e) => e.params[kPersonParamID] as String)
            .toList();
      } else {
        _logger.warning("No selected people found");
      }
    }

    return peopleIds ?? [];
  }

  Future<Map<String, (String, Iterable<EnteFile>)>> _getPeople() async {
    final peopleIds = await _getEffectiveSelectedPeopleIds();
    final Map<String, (String, Iterable<EnteFile>)> peopleFiles = {};

    for (final id in peopleIds) {
      final person = await PersonService.instance.getPerson(id);
      if (person == null) {
        _logger.warning("Person not found for id: $id");
        continue;
      }

      final clusterFiles =
          await SearchService.instance.getClusterFilesForPersonID(id);
      final files = clusterFiles.entries.expand((e) => e.value).toList();
      if (files.isEmpty) {
        _logger.warning("No files found for person: ${person.data.name}");
        continue;
      }
      peopleFiles[id] = (person.data.name, files);
    }

    return peopleFiles;
  }

  Future<void> _refreshWidget({String? message}) async {
    await HomeWidgetService.instance.updateWidget(
      androidClass: ANDROID_CLASS_NAME,
      iOSClass: IOS_CLASS_NAME,
    );

    if (flagService.internalUser) {
      await Fluttertoast.showToast(
        msg: "[i][ppl] ${message ?? "PeopleHomeWidget updated"}",
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

  Future<int?> _getTotalPeople() async {
    return HomeWidgetService.instance.getData<int>(TOTAL_PEOPLE_KEY);
  }

  Future<void> _setTotalPeople(int? total) async {
    await HomeWidgetService.instance.setData(TOTAL_PEOPLE_KEY, total);
  }

  Future<void> _loadAndRenderPeople() async {
    final peopleIds = await _getEffectiveSelectedPeopleIds();
    final peopleWithFiles = await _getPeople();

    if (peopleWithFiles.isEmpty) {
      _logger.warning("No files found for any people, clearing widget");
      await clearWidget();
      return;
    }

    final currentTotal = await _getTotalPeople();
    _logger.info("Current total people in widget: $currentTotal");

    final bool isWidgetPresent = await countHomeWidgets() > 0;

    final limit = isWidgetPresent ? MAX_PEOPLE_LIMIT : 5;
    final maxAttempts = limit * 10;

    int renderedCount = 0;
    int attemptsCount = 0;

    await updatePeopleStatus(WidgetStatus.notSynced);

    final peopleWithFilesLength = peopleWithFiles.length;
    final peopleWithFilesEntries = peopleWithFiles.entries.toList();
    final random = Random();

    while (renderedCount < limit && attemptsCount < maxAttempts) {
      final randomEntry =
          peopleWithFilesEntries[random.nextInt(peopleWithFilesLength)];

      if (randomEntry.value.$2.isEmpty) continue;

      final randomPersonFile = randomEntry.value.$2.elementAt(
        random.nextInt(randomEntry.value.$2.length),
      );
      final personId = randomEntry.key;
      final personName = randomEntry.value.$1;

      final renderResult = await HomeWidgetService.instance
          .renderFile(
        randomPersonFile,
        "people_widget_$renderedCount",
        personName,
        personId,
      )
          .catchError((e, stackTrace) {
        _logger.severe("Error rendering widget", e, stackTrace);
        return null;
      });

      if (renderResult != null) {
        // Check for blockers again before continuing
        if (await _hasAnyBlockers()) {
          return;
        }

        await _setTotalPeople(renderedCount);

        // Show update toast after first item is rendered
        if (renderedCount == 1) {
          await _refreshWidget(
            message: "First person fetched, updating widget",
          );
          await updatePeopleStatus(WidgetStatus.syncedPartially);
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

    if (renderedCount == 0) {
      return;
    }

    if (isWidgetPresent) {
      await updatePeopleStatus(WidgetStatus.syncedAll);
    }

    final hash = await _calculateHash(peopleIds);
    await setPeopleLastHash(hash);

    await _refreshWidget(
      message: "Switched to next people set, total: $renderedCount",
    );
  }
}
