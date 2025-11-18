import "dart:convert";
import "dart:io";

import "package:logging/logging.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import "package:photos/models/faces_timeline/faces_timeline_models.dart";
import "package:synchronized/synchronized.dart";

class FacesTimelineCacheService {
  FacesTimelineCacheService._internal();

  static final FacesTimelineCacheService instance =
      FacesTimelineCacheService._internal();

  static const _cacheDirectoryName = "faces_timeline";
  static const _cacheFileName = "cache.json";

  final Logger _logger = Logger("FacesTimelineCacheService");
  final Lock _lock = Lock();

  FacesTimelineCachePayload? _cache;
  File? _cacheFile;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    final directory = await getApplicationDocumentsDirectory();
    final cacheDirectory = Directory(
      p.join(directory.path, _cacheDirectoryName),
    );
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }
    final file = File(p.join(cacheDirectory.path, _cacheFileName));

    await _lock.synchronized(() async {
      _cacheFile = file;
      if (!await file.exists()) {
        _cache = FacesTimelineCachePayload.empty();
        await _writeCacheUnsafe();
      } else {
        await _loadCacheUnsafe();
      }
      _initialized = true;
    });
  }

  Future<FacesTimelineCachePayload> getCache() async {
    await _ensureInitialized();
    return _lock.synchronized(() async {
      _cache ??= await _loadCacheUnsafe();
      return _cache!;
    });
  }

  Future<FacesTimelinePersonTimeline?> getTimeline(String personId) async {
    final cache = await getCache();
    return cache[personId];
  }

  Future<FacesTimelineComputeLogEntry?> getComputeLogEntry(
    String personId,
  ) async {
    final cache = await getCache();
    return cache.computeLog[personId];
  }

  Future<Map<String, FacesTimelineComputeLogEntry>> getComputeLog() async {
    final cache = await getCache();
    return Map<String, FacesTimelineComputeLogEntry>.from(cache.computeLog);
  }

  Future<void> upsertTimeline(FacesTimelinePersonTimeline timeline) async {
    await _ensureInitialized();
    await _lock.synchronized(() async {
      final currentCache = await _loadCacheUnsafe();
      final updatedCache = currentCache.copyWithTimeline(timeline);
      _cache = updatedCache;
      await _writeCacheUnsafe();
    });
  }

  Future<void> upsertComputeLogEntry(
    FacesTimelineComputeLogEntry entry,
  ) async {
    await _ensureInitialized();
    await _lock.synchronized(() async {
      final currentCache = await _loadCacheUnsafe();
      final updatedCache = currentCache.copyWithComputeLogEntry(entry);
      _cache = updatedCache;
      await _writeCacheUnsafe();
    });
  }

  Future<void> removeComputeLogEntry(String personId) async {
    await _ensureInitialized();
    await _lock.synchronized(() async {
      final currentCache = await _loadCacheUnsafe();
      if (!currentCache.computeLog.containsKey(personId)) {
        return;
      }
      final updatedLog = Map<String, FacesTimelineComputeLogEntry>.from(
        currentCache.computeLog,
      )..remove(personId);
      _cache = currentCache.copyWithComputeLog(
        entries: updatedLog,
        logVersion: currentCache.computeLogVersion,
      );
      await _writeCacheUnsafe();
    });
  }

  Future<void> ensureComputeLogVersion(int version) async {
    await _ensureInitialized();
    await _lock.synchronized(() async {
      final currentCache = await _loadCacheUnsafe();
      if (currentCache.computeLogVersion == version) {
        return;
      }
      _cache = currentCache.copyWithComputeLog(
        entries: {},
        logVersion: version,
      );
      await _writeCacheUnsafe();
    });
  }

  Future<void> removeTimeline(String personId) async {
    await _ensureInitialized();
    await _lock.synchronized(() async {
      final currentCache = await _loadCacheUnsafe();
      if (!currentCache.timelines.containsKey(personId)) {
        return;
      }
      final updatedCache = currentCache.copyWithoutPerson(personId);
      _cache = updatedCache;
      await _writeCacheUnsafe();
    });
  }

  Future<void> replaceAll(FacesTimelineCachePayload payload) async {
    await _ensureInitialized();
    await _lock.synchronized(() async {
      _cache = payload;
      await _writeCacheUnsafe();
    });
  }

  Future<void> clear() async {
    await _ensureInitialized();
    await _lock.synchronized(() async {
      _cache = FacesTimelineCachePayload.empty();
      await _writeCacheUnsafe();
    });
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await init();
  }

  Future<FacesTimelineCachePayload> _loadCacheUnsafe() async {
    if (_cache != null) return _cache!;
    final file = _cacheFile;
    if (file == null) {
      _logger.severe("Faces timeline cache accessed before initialization");
      _cache = FacesTimelineCachePayload.empty();
      return _cache!;
    }
    try {
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) {
        _cache = FacesTimelineCachePayload.empty();
        return _cache!;
      }
      final decoded = jsonDecode(contents);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException("Timeline cache is not a JSON map");
      }
      _cache = FacesTimelineCachePayload.fromJson(decoded);
      return _cache!;
    } catch (error, stackTrace) {
      _logger.severe("Failed to read faces timeline cache", error, stackTrace);
      _cache = FacesTimelineCachePayload.empty();
      await _writeCacheUnsafe();
      return _cache!;
    }
  }

  Future<void> _writeCacheUnsafe() async {
    final file = _cacheFile;
    if (file == null) {
      _logger.severe("Faces timeline cache file missing during write");
      return;
    }
    final payload = _cache ?? FacesTimelineCachePayload.empty();
    try {
      await file.writeAsString(payload.toEncodedJson(), flush: true);
    } catch (error, stackTrace) {
      _logger.severe("Failed to write faces timeline cache", error, stackTrace);
      rethrow;
    }
  }
}
