import "dart:convert";
import 'dart:math';

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
    if (jsonFile == null) {}
  }

  Future<Map<String, List<int>>> getMatchingFileIDsForPromptData(
    Map<String, Object> promptData,
  ) async {
    final result = await SemanticSearchService.instance.getMatchingFileIDs(
      promptData["prompt"] as String,
      promptData["minimumScore"] as double,
    );

    return {promptData["title"] as String: result};
  }

  Future<void> updateMagicCache() async {
    final magicCaches = <MagicCache>[];
    await prefs.setString(
      _key,
      MagicCache.encodeListToJson(magicCaches),
    );
  }

  Future<List<MagicCache>?> getMagicCache() async {
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
    final magicCaches = await getMagicCache();
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

  ///Generates from 0 to max non-repeating random numbers
  List<int> _generateUniqueRandomNumbers(int max, int count) {
    final numbers = <int>[];
    for (int i = 1; i <= count;) {
      final randomNumber = Random().nextInt(max + 1);
      if (numbers.contains(randomNumber)) {
        continue;
      }
      numbers.add(randomNumber);
      i++;
    }
    return numbers;
  }
}
