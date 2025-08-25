import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/file_uploaded_event.dart";
import "package:photos/events/magic_cache_updated_event.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/discover/prompt.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import "package:photos/models/search/hierarchical/magic_filter.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/viewer/search/result/magic_result_screen.dart";
import "package:photos/utils/cache_util.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/text_embeddings_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class MagicCache {
  final String title;
  final List<int> fileUploadedIDs;
  Map<int, int>? _fileIdToPositionMap;

  MagicCache(this.title, this.fileUploadedIDs);

  // Get map of uploadID to index in fileUploadedIDs
  Map<int, int> get fileIdToPositionMap {
    if (_fileIdToPositionMap == null) {
      _fileIdToPositionMap = {};
      for (int i = 0; i < fileUploadedIDs.length; i++) {
        _fileIdToPositionMap![fileUploadedIDs[i]] = i;
      }
    }
    return _fileIdToPositionMap!;
  }

  factory MagicCache.fromJson(Map<String, dynamic> json) {
    return MagicCache(
      json['title'],
      List<int>.from(json['fileUploadedIDs']),
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

String getLocalizedTitle(BuildContext context, String title) {
  switch (title) {
    case 'Identity':
      return context.l10n.discover_identity;
    case 'Screenshots':
      return context.l10n.discover_screenshots;
    case 'Receipts':
      return context.l10n.discover_receipts;
    case 'Notes':
      return context.l10n.discover_notes;
    case 'Memes':
      return context.l10n.discover_memes;
    case 'Visiting Cards':
      return context.l10n.discover_visiting_cards;
    case 'Babies':
      return context.l10n.discover_babies;
    case 'Pets':
      return context.l10n.discover_pets;
    case 'Selfies':
      return context.l10n.discover_selfies;
    case 'Wallpapers':
      return context.l10n.discover_wallpapers;
    case 'Food':
      return context.l10n.discover_food;
    case 'Celebrations':
      return context.l10n.discover_celebrations;
    case 'Sunset':
      return context.l10n.discover_sunset;
    case 'Hills':
      return context.l10n.discover_hills;
    case 'Greenery':
      return context.l10n.discover_greenery;
    default:
      return title; // If no match, return the original string
  }
}

GenericSearchResult? toGenericSearchResult(
  BuildContext context,
  Prompt prompt,
  List<EnteFile> enteFilesInMagicCache,
  Map<int, int> fileIdToPositionMap,
) {
  if (enteFilesInMagicCache.isEmpty) {
    return null;
  }
  if (!prompt.recentFirst) {
    enteFilesInMagicCache.sort((a, b) {
      final aID = a.uploadedFileID;
      final bID = b.uploadedFileID;
      if (aID == null || bID == null) return 0;
      final aPos = fileIdToPositionMap[aID];
      final bPos = fileIdToPositionMap[bID];
      if (aPos == null || bPos == null) return 0;
      return aPos.compareTo(bPos);
    });
  }
  final String title = getLocalizedTitle(context, prompt.title);
  return GenericSearchResult(
    ResultType.magic,
    title,
    enteFilesInMagicCache,
    params: {
      "enableGrouping": prompt.recentFirst,
      "fileIdToPosMap": fileIdToPositionMap,
    },
    onResultTap: (ctx) {
      routeToPage(
        ctx,
        MagicResultScreen(
          enteFilesInMagicCache,
          name: title,
          enableGrouping: prompt.recentFirst,
          fileIdToPosMap: fileIdToPositionMap,
          heroTag: GenericSearchResult(
            ResultType.magic,
            title,
            enteFilesInMagicCache,
            hierarchicalSearchFilter: MagicFilter(
              filterName: title,
              occurrence: kMostRelevantFilter,
              matchedUploadedIDs: filesToUploadedFileIDs(enteFilesInMagicCache),
            ),
          ).heroTag(),
          magicFilter: MagicFilter(
            filterName: title,
            occurrence: kMostRelevantFilter,
            matchedUploadedIDs: filesToUploadedFileIDs(enteFilesInMagicCache),
          ),
        ),
      );
    },
    hierarchicalSearchFilter: MagicFilter(
      filterName: title,
      occurrence: kMostRelevantFilter,
      matchedUploadedIDs: filesToUploadedFileIDs(enteFilesInMagicCache),
    ),
  );
}

class MagicCacheService {
  static const _lastMagicCacheUpdateTime = "last_magic_cache_update_time";

  /// Delay is for cache update to be done not during app init, during which a
  /// lot of other things are happening.
  static const _kCacheUpdateDelay = Duration(seconds: 10);

  final SharedPreferences _prefs;
  late final Logger _logger = Logger((MagicCacheService).toString());

  Future<List<MagicCache>>? _magicCacheFuture;
  final Set<String> _pendingUpdateReason = {};
  bool _isUpdateInProgress = false;

  MagicCacheService(this._prefs) {
    _logger.info("MagicCacheService constructor");
    Bus.instance.on<FileUploadedEvent>().listen((event) {
      queueUpdate("File uploaded");
    });
    Future.delayed(_kCacheUpdateDelay, () {
      _updateCacheIfTheTimeHasCome();
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

  bool get enableDiscover => flagService.hasGrantedMLConsent;

  void queueUpdate(String reason) {
    _pendingUpdateReason.add(reason);
  }

  Future<void> _updateCacheIfTheTimeHasCome() async {
    if (!enableDiscover) {
      return;
    }
    if (lastMagicCacheUpdateTime <
        DateTime.now()
            .subtract(const Duration(hours: 12))
            .millisecondsSinceEpoch) {
      queueUpdate("Cache is old");
    }
  }

  Future<String> _getCachePath() async {
    return (await getApplicationSupportDirectory()).path + "/cache/magic_cache";
  }

  Future<void> updateCache({bool forced = false}) async {
    if (!enableDiscover) {
      return;
    }
    if (forced) {
      _pendingUpdateReason.add("Forced update");
    }
    try {
      if (_pendingUpdateReason.isEmpty || _isUpdateInProgress) {
        _logger.info(
          "No update needed as ${_pendingUpdateReason.toList()} and isUpdateInProgress $_isUpdateInProgress",
        );
        return;
      }
      _logger.info("updating magic cache ${_pendingUpdateReason.toList()}");
      _isUpdateInProgress = true;
      final EnteWatch? w = kDebugMode ? EnteWatch("magicCacheWatch") : null;
      w?.start();
      final List<MagicCache> magicCaches = await _nonEmptyMagicResults();
      w?.log("resultComputed");
      _magicCacheFuture = Future.value(magicCaches);
      await writeToJsonFile<List<MagicCache>>(
        await _getCachePath(),
        magicCaches,
        MagicCache.encodeListToJson,
      );
      w?.log("cacheWritten");
      await _resetLastMagicCacheUpdateTime();
      w?.logAndReset('done');
      _pendingUpdateReason.clear();
    } catch (e, s) {
      _logger.info("Error updating magic cache", e, s);
    } finally {
      _isUpdateInProgress = false;
      Bus.instance.fire(MagicCacheUpdatedEvent());
    }
  }

  Future<List<MagicCache>> getMagicCache() async {
    if (_magicCacheFuture != null) {
      return _magicCacheFuture!;
    }
    _magicCacheFuture = _readResultFromDisk();
    return _magicCacheFuture!;
  }

  Future<List<MagicCache>> _readResultFromDisk() async {
    _logger.info("Reading magic cache result from disk");
    final cache = await decodeJsonFile<List<MagicCache>>(
      await _getCachePath(),
      MagicCache.decodeJsonToList,
    );
    return cache ?? [];
  }

  Future<void> clearMagicCache() async {
    final file = File(await _getCachePath());
    if (file.existsSync()) {
      await file.delete();
    }
    _magicCacheFuture = null;
  }

  Future<List<GenericSearchResult>> getMagicGenericSearchResult(
    BuildContext context,
  ) async {
    try {
      final EnteWatch? w =
          kDebugMode ? EnteWatch("magicGenericSearchResult") : null;
      w?.start();
      final magicCaches = await getMagicCache();

      // Load discover embeddings to get prompts
      final discoverEmbeddings = await loadDiscoverEmbeddings();
      if (discoverEmbeddings == null) {
        _logger.severe("No discover embeddings available in assets");
        throw Exception("No discover embeddings available in assets");
      }

      final prompts = <Prompt>[];
      for (final entry in discoverEmbeddings.queryToPromptData.entries) {
        final query = entry.key;
        final promptData = entry.value;
        prompts.add(
          Prompt(
            query: query,
            title: promptData.title,
            minScore: promptData.minScore,
            minSize: promptData.minSize,
            showVideo: promptData.showVideo ?? true,
            recentFirst: promptData.recentFirst ?? false,
          ),
        );
      }

      if (magicCaches.isEmpty) {
        w?.log("No magic cache found");
        return [];
      } else {
        w?.log("cacheFound");
      }
      final Map<String, List<EnteFile>> magicIdToFiles = {};

      final Map<String, Prompt> promptMap = {};
      final Map<String, Map<int, int>> promptFileOrder = {};
      for (MagicCache c in magicCaches) {
        magicIdToFiles[c.title] = [];
        promptFileOrder[c.title] = c.fileIdToPositionMap;
      }
      for (final p in prompts) {
        promptMap[p.title] = p;
      }
      final List<GenericSearchResult> genericSearchResults = [];
      final List<EnteFile> files =
          await SearchService.instance.getAllFilesForSearch();
      for (EnteFile file in files) {
        if (!file.isUploaded) continue;
        for (MagicCache magicCache in magicCaches) {
          if (magicCache.fileIdToPositionMap
              .containsKey(file.uploadedFileID!)) {
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
          context,
          p,
          magicIdToFiles[p.title] ?? [],
          promptFileOrder[p.title] ?? {},
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

  Future<List<MagicCache>> _nonEmptyMagicResults() async {
    final TimeLogger t = TimeLogger();
    final results = <MagicCache>[];
    final List<int> matchCount = [];

    // Uncomment this code to generate embeddings and save them to a JSON file
    // await generateAndSaveDiscoverEmbeddings();
    // (from package:photos/utils/text_embeddings_util.dart)

    // Load pre-computed discover embeddings from assets
    final discoverEmbeddings = await loadDiscoverEmbeddings();
    if (discoverEmbeddings == null) {
      _logger.severe('Failed to load discover embeddings');
      throw Exception('Failed to load discover embeddings');
    }

    // Build the embeddings and score maps
    final Map<String, List<double>> queryToEmbedding = {};
    final Map<String, double> queryToScore = {};
    final List<Prompt> prompts = [];

    for (final entry in discoverEmbeddings.queryToPromptData.entries) {
      final query = entry.key;
      final promptData = entry.value;
      final vector = discoverEmbeddings.queryToVector[query];

      if (vector != null) {
        queryToEmbedding[query] = vector.toList();
        queryToScore[query] = promptData.minScore;
        prompts.add(
          Prompt(
            query: query,
            title: promptData.title,
            minScore: promptData.minScore,
            minSize: promptData.minSize,
            showVideo: promptData.showVideo ?? true,
            recentFirst: promptData.recentFirst ?? false,
          ),
        );
      }
    }

    _logger.info('Using pre-computed discover embeddings from assets');
    final clipResults = await SemanticSearchService.instance
        .getMatchingFileIDsWithEmbeddings(queryToEmbedding, queryToScore);

    for (final prompt in prompts) {
      final List<int> fileUploadedIDs = clipResults[prompt.query] ?? [];
      if (fileUploadedIDs.isNotEmpty) {
        results.add(
          MagicCache(prompt.title, fileUploadedIDs),
        );
      }
      matchCount.add(fileUploadedIDs.length);
    }
    _logger.info('magic result count $matchCount $t');
    return results;
  }
}
