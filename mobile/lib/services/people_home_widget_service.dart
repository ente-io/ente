import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/home_widget_service.dart';
import 'package:photos/services/machine_learning/face_ml/person/person_service.dart';
import 'package:photos/services/search_service.dart';
import 'package:photos/services/sync/local_sync_service.dart';
import 'package:photos/ui/viewer/file/file_widget.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

class PeopleHomeWidgetService {
  // Constants
  static const String SELECTED_PEOPLE_KEY = "selectedPeopleHW";
  static const String ANDROID_CLASS_NAME = "EntePeopleWidgetProvider";
  static const String IOS_CLASS_NAME = "EntePeopleWidget";
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
    await _refreshWidget(message: "PeopleHomeWidget cleared & updated");
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

  Future<void> peopleChanged() async {
    await updatePeopleChanged(true);

    final cachedMemories = await _getPeople();
    final currentTotal = cachedMemories.length;
    final existingTotal = await _getTotalPeople() ?? 0;

    if (existingTotal == currentTotal && existingTotal == 0) {
      await updatePeopleChanged(false);
      _logger.info("People empty, no update needed");
      return;
    }

    _logger.info("People changed, updating widget");
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

    await routeToPage(
      context,
      FileWidget(
        file,
        tagPrefix: "peoplewidget",
      ),
    );
  }

  // Private methods
  Future<void> _forcePeopleUpdate() async {
    await _loadAndRenderPeople();
    await updatePeopleChanged(false);
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
      _logger.warning("Error looking up people: $e");
      return true;
    }

    // TODO: If peopleIds are null then check if SearchFilter contains at least one

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
    return peopleChanged ?? true;
  }

  Future<Map<String, (String, Iterable<EnteFile>)>> _getPeople() async {
    final peopleIds = getSelectedPeople();
    final Map<String, (String, Iterable<EnteFile>)> peopleFiles = {};

    for (final id in peopleIds ?? []) {
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
    final peopleWithFiles = await _getPeople();

    if (peopleWithFiles.isEmpty) {
      _logger.warning("No files found for any people, clearing widget");
      await clearWidget();
      return;
    }

    final currentTotal = await _getTotalPeople();
    _logger.info("Current total people in widget: $currentTotal");

    int renderedCount = 0;

    final bool isWidgetPresent = await countHomeWidgets() > 0;
    final limit = isWidgetPresent ? MAX_PEOPLE_LIMIT : 5;

    for (final entry in peopleWithFiles.entries) {
      final personId = entry.key;
      final personName = entry.value.$1;
      final personFiles = entry.value.$2;

      for (final file in personFiles) {
        final renderResult = await HomeWidgetService.instance
            .renderFile(
          file,
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
          }

          renderedCount++;

          // Limit the number of people to avoid performance issues
          if (renderedCount >= limit) {
            _logger.warning("Maximum people limit ($limit) reached");
            break;
          }
        }
      }

      if (renderedCount >= limit) {
        break;
      }
    }

    if (renderedCount == 0) {
      return;
    }

    await _refreshWidget(
      message: "Switched to next people set, total: $renderedCount",
    );
  }
}
