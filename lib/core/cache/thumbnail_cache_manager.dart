import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ThumbnailCacheManager extends BaseCacheManager {
  static const key = 'cached-thumbnail-data';

  static ThumbnailCacheManager _instance;

  factory ThumbnailCacheManager() {
    _instance ??= ThumbnailCacheManager._();
    return _instance;
  }

  ThumbnailCacheManager._() : super(key, maxNrOfCacheObjects: 20000);

  @override
  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return p.join(directory.path, key);
  }
}
