import "dart:async";
import "dart:convert";
import "dart:io";

import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/services/remote_assets_service.dart";
import "package:photos/services/search_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class MagicCache {
  final String title;
  final List<int> fileUploadedIDs;
  MagicCache(this.title, this.fileUploadedIDs);

  factory MagicCache.fromJson(Map<String, dynamic> json) {
    return MagicCache(
      json['title'],
      List<int>.from(json['fileUploadedIDs']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fileUploadedIDs': fileUploadedIDs,
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

extension MagicCacheServiceExtension on MagicCache {
  Future<GenericSearchResult> toGenericSearchResult() async {
    final allEnteFiles = await SearchService.instance.getAllFiles();
    final enteFilesInMagicCache = <EnteFile>[];
    for (EnteFile file in allEnteFiles) {
      if (file.uploadedFileID != null &&
          fileUploadedIDs.contains(file.uploadedFileID as int)) {
        enteFilesInMagicCache.add(file);
      }
    }
    return GenericSearchResult(
      ResultType.magic,
      title,
      enteFilesInMagicCache,
    );
  }
}

class MagicCacheService {
  static const _lastMagicCacheUpdateTime = "last_magic_cache_update_time";
  static const _kMagicPromptsDataUrl = "https://discover.ente.io/v1.json";

  /// Delay is for cache update to be done not during app init, during which a
  /// lot of other things are happening.
  static const _kCacheUpdateDelay = Duration(seconds: 10);

  late SharedPreferences _prefs;
  final Logger _logger = Logger((MagicCacheService).toString());
  MagicCacheService._privateConstructor();

  static final MagicCacheService instance =
      MagicCacheService._privateConstructor();

  void init(SharedPreferences preferences) {
    _prefs = preferences;
    _updateCacheIfTheTimeHasCome();
  }

  Future<void> resetLastMagicCacheUpdateTime() async {
    await _prefs.setInt(
      _lastMagicCacheUpdateTime,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  int get lastMagicCacheUpdateTime {
    return _prefs.getInt(_lastMagicCacheUpdateTime) ?? 0;
  }

  Future<void> _updateCacheIfTheTimeHasCome() async {
    final jsonFile = await RemoteAssetsService.instance
        .getAssetIfUpdated(_kMagicPromptsDataUrl);
    if (jsonFile != null) {
      Future.delayed(_kCacheUpdateDelay, () {
        unawaited(_updateCache());
      });
      return;
    }
    if (lastMagicCacheUpdateTime <
        DateTime.now()
            .subtract(const Duration(days: 3))
            .millisecondsSinceEpoch) {
      Future.delayed(_kCacheUpdateDelay, () {
        unawaited(_updateCache());
      });
    }
  }

  Future<String> _getCachePath() async {
    return (await getApplicationSupportDirectory()).path + "/cache/magic_cache";
  }

  Future<List<int>> _getMatchingFileIDsForPromptData(
    Map<String, dynamic> promptData,
  ) async {
    final result = await SemanticSearchService.instance.getMatchingFileIDs(
      promptData["prompt"] as String,
      promptData["minimumScore"] as double,
    );

    return result;
  }

  Future<void> _updateCache() async {
    try {
      _logger.info("updating magic cache");
      final magicPromptsData = await _loadMagicPrompts();
      final magicCaches = await nonEmptyMagicResults(magicPromptsData);
      final file = File(await _getCachePath());
      if (!file.existsSync()) {
        file.createSync(recursive: true);
      }
      file.writeAsBytesSync(MagicCache.encodeListToJson(magicCaches).codeUnits);
      unawaited(
        resetLastMagicCacheUpdateTime().onError((error, stackTrace) {
          _logger.warning(
            "Error resetting last magic cache update time",
            error,
          );
        }),
      );
    } catch (e) {
      _logger.info("Error updating magic cache", e);
    }
  }

  Future<List<MagicCache>?> _getMagicCache() async {
    final file = File(await _getCachePath());
    if (!file.existsSync()) {
      _logger.info("No magic cache found");
      return null;
    }
    final jsonString = file.readAsStringSync();
    return MagicCache.decodeJsonToList(jsonString);
  }

  Future<void> clearMagicCache() async {
    File(await _getCachePath()).deleteSync();
  }

  Future<List<GenericSearchResult>> getMagicGenericSearchResult() async {
    try {
      final magicCaches = await _getMagicCache();
      if (magicCaches == null) {
        _logger.info("No magic cache found");
        return [];
      }

      final List<GenericSearchResult> genericSearchResults = [];
      for (MagicCache magicCache in magicCaches) {
        final genericSearchResult = await magicCache.toGenericSearchResult();
        genericSearchResults.add(genericSearchResult);
      }
      return genericSearchResults;
    } catch (e) {
      _logger.info("Error getting magic generic search result", e);
      return [];
    }
  }

  Future<List<dynamic>> _loadMagicPrompts() async {
    final file =
        await RemoteAssetsService.instance.getAsset(_kMagicPromptsDataUrl);

    final json = jsonDecode(await file.readAsString());
    return json["prompts"];
  }

  ///Returns random non-empty magic results from magicPromptsData
  ///Length is capped at [limit], can be less than [limit] if there are not enough
  ///non-empty results
  Future<List<MagicCache>> nonEmptyMagicResults(
    List<dynamic> magicPromptsData,
  ) async {
    //Show all magic prompts to internal users for feedback on results
    final limit = flagService.internalUser ? magicPromptsData.length : 4;
    final results = <MagicCache>[];
    final randomIndexes = List.generate(
      magicPromptsData.length,
      (index) => index,
      growable: false,
    )..shuffle();
    for (final index in randomIndexes) {
      final files =
          await _getMatchingFileIDsForPromptData(magicPromptsData[index]);
      if (files.isNotEmpty) {
        results.add(
          MagicCache(
            magicPromptsData[index]["title"] as String,
            files,
          ),
        );
      }
      if (results.length >= limit) {
        break;
      }
    }
    return results;
  }
}
