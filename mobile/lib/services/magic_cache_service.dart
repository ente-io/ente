import "dart:async";
import "dart:convert";

import "package:logging/logging.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_types.dart";
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
  static const _key = "magic_cache";
  static const _kMagicPromptsDataUrl = "https://discover.ente.io/v1.json";

  late SharedPreferences prefs;
  final Logger _logger = Logger((MagicCacheService).toString());
  MagicCacheService._privateConstructor();

  static final MagicCacheService instance =
      MagicCacheService._privateConstructor();

  void init(SharedPreferences preferences) {
    prefs = preferences;
    _updateCacheIfNeeded();
  }

  Future<void> _updateCacheIfNeeded() async {
    final jsonFile = await RemoteAssetsService.instance
        .getAssetIfUpdated(_kMagicPromptsDataUrl);
    if (jsonFile != null) {
      Future.delayed(const Duration(seconds: 10), () {
        unawaited(updateMagicCache());
      });
    }
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

  Future<void> updateMagicCache() async {
    final magicPromptsData = await _loadMagicPrompts();
    final magicCaches = await nonEmptyMagicResults(magicPromptsData);
    await prefs.setString(
      _key,
      MagicCache.encodeListToJson(magicCaches),
    );
  }

  Future<List<MagicCache>?> _getMagicCache() async {
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      _logger.info("No $_key in shared preferences");
      return null;
    }
    return MagicCache.decodeJsonToList(jsonString);
  }

  Future<void> clearMagicCache() async {
    await prefs.remove(_key);
  }

  Future<List<GenericSearchResult>> getMagicGenericSearchResult() async {
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
    const limit = 4;
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
