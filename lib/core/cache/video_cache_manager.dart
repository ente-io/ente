import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class VideoCacheManager extends BaseCacheManager {
  static const key = 'cached-video-data';

  static VideoCacheManager _instance;

  factory VideoCacheManager() {
    _instance ??= VideoCacheManager._();
    return _instance;
  }

  VideoCacheManager._() : super(key, maxNrOfCacheObjects: 50);

  @override
  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return p.join(directory.path, key);
  }
}
