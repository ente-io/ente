import "package:flutter/foundation.dart";
import "package:photos/core/cache/lru_map.dart";
import "package:photos/models/file/file.dart";

// Singleton instance for global access
final enteImageCache = InMemoryImageCache._instance;

class InMemoryImageCache {
  static final InMemoryImageCache _instance = InMemoryImageCache._();

  // Private constructor for singleton
  InMemoryImageCache._();

  // Supported dimensions with associated cache sizes
  static const Map<int, int> _cacheSizes = {
    32: 5000, // Small: 32*32 = 1024 bytes * 5000 = 6.25MB
    256: 2000, // Medium: 256*256 = 65536 bytes * 2000 = 128MB
    512: 100, // Large: 512*512 = 262144 bytes * 100 = 25MB
  };

  // Cache instances for each dimension
  final Map<int, LRUMap<String, Uint8List?>> _caches = {
    32: LRUMap<String, Uint8List?>(5000),
    256: LRUMap<String, Uint8List?>(2000),
    512: LRUMap<String, Uint8List?>(100),
  };

  /// Gets a thumbnail for a file at the specified dimension
  Uint8List? getThumb(EnteFile file, int dimension) {
    return _getFromCache(file.cacheKey(), dimension);
  }

  /// Gets a thumbnail by ID at the specified dimension
  Uint8List? getThumbByID(String id, int dimension) {
    return _getFromCache(id, dimension);
  }

  /// Stores a thumbnail for a file at the specified dimension
  void putThumb(EnteFile file, Uint8List? imageData, int dimension) {
    _putInCache(file.cacheKey(), imageData, dimension);
  }

  /// Stores a thumbnail by ID at the specified dimension
  void putThumbByID(String id, Uint8List? imageData, int dimension) {
    _putInCache(id, imageData, dimension);
  }

  /// Checks if a thumbnail exists for a file at the specified dimension
  bool containsThumb(EnteFile file, int dimension) {
    return _isCached(file.cacheKey(), dimension);
  }

  void clearCache(EnteFile file) {
    _caches.forEach((_, cache) {
      cache.remove(file.cacheKey());
    });
  }

  // Private helper methods

  Uint8List? _getFromCache(String key, int dimension) {
    if (_isValidDimension(dimension)) {
      return _caches[dimension]?.get(key);
    }
    return null;
  }

  void _putInCache(String key, Uint8List? imageData, int dimension) {
    if (_isValidDimension(dimension)) {
      _caches[dimension]?.put(key, imageData);
    } else {
      debugPrint("Unsupported dimension: $dimension");
    }
  }

  bool _isCached(String key, int dimension) {
    if (_isValidDimension(dimension)) {
      return _caches[dimension]?.containsKey(key) ?? false;
    }
    return false;
  }

  bool _isValidDimension(int dimension) {
    if (_caches.containsKey(dimension)) {
      return true;
    }
    debugPrint("Invalid dimension: $dimension");
    return false;
  }
}
