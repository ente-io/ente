import "dart:async";
import "dart:convert";
import "dart:io";

import "package:computer/computer.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/file_uploaded_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/discover/prompt.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/viewer/search/result/magic_result_screen.dart";
import "package:photos/utils/navigation_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class MagicCache {
  final String title;
  final Set<int> fileUploadedIDs;
  MagicCache(this.title, this.fileUploadedIDs);

  factory MagicCache.fromJson(Map<String, dynamic> json) {
    return MagicCache(
      json['title'],
      Set<int>.from(json['fileUploadedIDs']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fileUploadedIDs': fileUploadedIDs.toList(),
    };
  }

  static String encodeListToJson(List<MagicCache> magicCaches) {
    final jsonList = magicCaches.map((cache) => cache.toJson()).toList();
    return jsonEncode(jsonList);
  }

  static List<MagicCache> decodeJsonToList(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => MagicCache.fromJson(json)).toList();
  }
}

GenericSearchResult? toGenericSearchResult(
  Prompt prompt,
  List<EnteFile> enteFilesInMagicCache,
) {
  if (enteFilesInMagicCache.isEmpty) {
    return null;
  }
  return GenericSearchResult(
    ResultType.magic,
    prompt.title,
    enteFilesInMagicCache,
    onResultTap: (ctx) {
      routeToPage(
        ctx,
        MagicResultScreen(
          enteFilesInMagicCache,
          name: prompt.title,
          enableGrouping: prompt.recentFirst,
          heroTag: GenericSearchResult(
            ResultType.magic,
            prompt.title,
            enteFilesInMagicCache,
          ).heroTag(),
        ),
      );
    },
  );
}

class MagicCacheService {
  static const _lastMagicCacheUpdateTime = "last_magic_cache_update_time";
  static const _kMagicPromptsDataUrl = "https://discover.ente.io/v2.json";

  /// Delay is for cache update to be done not during app init, during which a
  /// lot of other things are happening.
  static const _kCacheUpdateDelay = Duration(seconds: 10);

  late SharedPreferences _prefs;
  final Logger _logger = Logger((MagicCacheService).toString());
  MagicCacheService._privateConstructor();

  Future<List<MagicCache>>? _magicCacheFuture;
  Future<List<Prompt>>? _promptFuture;
  final Set<String> _pendingUpdateReason = {};
  bool _isUpdateInProgress = false;

  static final MagicCacheService instance =
      MagicCacheService._privateConstructor();

  void init(SharedPreferences preferences) {
    _logger.info("Initializing MagicCacheService");
    _prefs = preferences;
    Future.delayed(_kCacheUpdateDelay, () {
      _updateCacheIfTheTimeHasCome();
    });
    Bus.instance.on<FileUploadedEvent>().listen((event) {
      _pendingUpdateReason.add("File uploaded");
    });
  }

  Future<void> _resetLastMagicCacheUpdateTime() async {
    await _prefs.setInt(
      _lastMagicCacheUpdateTime,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  int get lastMagicCacheUpdateTime {
    return _prefs.getInt(_lastMagicCacheUpdateTime) ?? 0;
  }

  bool get enableDiscover =>
      localSettings.isMLIndexingEnabled && flagService.internalUser;

  Future<void> _updateCacheIfTheTimeHasCome() async {
    if (!enableDiscover) {
      return;
    }
    final updatedJSONFile = await RemoteAssetsService.instance
        .getAssetIfUpdated(_kMagicPromptsDataUrl);
    if (updatedJSONFile != null) {
      _pendingUpdateReason.add("Prompts data updated");
    } else {
      if (lastMagicCacheUpdateTime <
          DateTime.now()
              .subtract(const Duration(days: 3))
              .millisecondsSinceEpoch) {
        _pendingUpdateReason.add("Cache is old");
      }
    }
  }

  Future<String> _getCachePath() async {
    return (await getApplicationSupportDirectory()).path + "/cache/magic_cache";
  }

  Future<void> updateCache() async {
    if (!enableDiscover) {
      return;
    }
    try {
      if (_pendingUpdateReason.isEmpty || _isUpdateInProgress) {
        _logger.info(
          "No update needed as ${_pendingUpdateReason.toList()} and isUpdateInProgress $_isUpdateInProgress",
        );
        return;
      }
      _logger.info("updating magic cache ${_pendingUpdateReason.toList()}");
      _pendingUpdateReason.clear();
      _isUpdateInProgress = true;
      final EnteWatch? w = kDebugMode ? EnteWatch("magicCacheWatch") : null;
      w?.start();
      final magicPromptsData = await getPrompts();
      w?.log("loadedPrompts");
      final List<MagicCache> magicCaches =
          await _nonEmptyMagicResults(magicPromptsData);
      w?.log("resultComputed");
      final file = File(await _getCachePath());
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      _magicCacheFuture = Future.value(magicCaches);
      await file
          .writeAsBytes(MagicCache.encodeListToJson(magicCaches).codeUnits);
      w?.log("cacheWritten");
      await _resetLastMagicCacheUpdateTime();
      w?.logAndReset('done');
    } catch (e, s) {
      _logger.info("Error updating magic cache", e, s);
    } finally {
      _isUpdateInProgress = false;
    }
  }

  Future<List<Prompt>> getPrompts() async {
    if (_promptFuture != null) {
      return _promptFuture!;
    }
    _promptFuture = _readPromptFromDiskOrNetwork();
    return _promptFuture!;
  }

  Future<List<MagicCache>> _getMagicCache() async {
    if (_magicCacheFuture != null) {
      return _magicCacheFuture!;
    }
    _magicCacheFuture = _readResultFromDisk();
    return _magicCacheFuture!;
  }

  Future<List<Prompt>> _readPromptFromDiskOrNetwork() async {
    final String path =
        await RemoteAssetsService.instance.getAssetPath(_kMagicPromptsDataUrl);
    return Computer.shared().compute(
      _loadMagicPrompts,
      param: <String, dynamic>{
        "path": path,
      },
    );
  }

  Future<List<MagicCache>> _readResultFromDisk() async {
    _logger.info("Reading magic cache result from disk");
    final file = File(await _getCachePath());
    if (!file.existsSync()) {
      _logger.info("No magic cache found");
      return [];
    }
    final jsonString = file.readAsStringSync();
    return MagicCache.decodeJsonToList(jsonString);
  }

  Future<void> clearMagicCache() async {
    await File(await _getCachePath()).delete();
  }

  Future<List<GenericSearchResult>> getMagicGenericSearchResult() async {
    try {
      final EnteWatch? w =
          kDebugMode ? EnteWatch("magicGenericSearchResult") : null;
      w?.start();
      final magicCaches = await _getMagicCache();
      final List<Prompt> prompts = await getPrompts();
      if (magicCaches.isEmpty) {
        w?.log("No magic cache found");
        return [];
      } else {
        w?.log("cacheFound");
      }
      final Map<String, List<EnteFile>> magicIdToFiles = {};
      final Map<String, Prompt> promptMap = {};
      for (MagicCache c in magicCaches) {
        magicIdToFiles[c.title] = [];
      }
      for (final p in prompts) {
        promptMap[p.title] = p;
      }
      final List<GenericSearchResult> genericSearchResults = [];
      final List<EnteFile> files = await SearchService.instance.getAllFiles();
      for (EnteFile file in files) {
        if (!file.isUploaded) continue;
        for (MagicCache magicCache in magicCaches) {
          if (magicCache.fileUploadedIDs.contains(file.uploadedFileID!)) {
            if (file.isVideo &&
                (promptMap[magicCache.title]?.showVideo ?? true) == false) {
              continue;
            }
            magicIdToFiles[magicCache.title]!.add(file);
          }
        }
      }
      for (final p in prompts) {
        final genericSearchResult = toGenericSearchResult(
          p,
          magicIdToFiles[p.title] ?? [],
        );
        if (genericSearchResult != null) {
          genericSearchResults.add(genericSearchResult);
        }
      }
      w?.logAndReset("done");
      return genericSearchResults;
    } catch (e, s) {
      _logger.info("Error getting magic generic search result", e, s);
      return [];
    }
  }

  static Future<List<Prompt>> _loadMagicPrompts(
    Map<String, dynamic> args,
  ) async {
    final String path = args["path"] as String;
    final File file = File(path);
    final String contents = await file.readAsString();
    final Map<String, dynamic> promptsJson = jsonDecode(contents);
    final List<dynamic> promptData = promptsJson['prompts'];
    return promptData
        .map<Prompt>((jsonItem) => Prompt.fromJson(jsonItem))
        .toList();
  }

  ///Returns non-empty magic results from magicPromptsData
  ///Length is number of prompts, can be less if there are not enough non-empty
  ///results
  Future<List<MagicCache>> _nonEmptyMagicResults(
    List<Prompt> magicPromptsData,
  ) async {
    final results = <MagicCache>[];
    for (Prompt prompt in magicPromptsData) {
      final fileUploadedIDs =
          await SemanticSearchService.instance.getMatchingFileIDs(
        prompt.query,
        prompt.minScore,
      );
      if (fileUploadedIDs.isNotEmpty) {
        results.add(
          MagicCache(prompt.title, fileUploadedIDs),
        );
      }
    }
    return results;
  }
}
