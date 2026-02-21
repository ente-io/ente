import 'dart:io';

import 'package:ente_configuration/base_configuration.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/favorites_service.dart';
import 'package:logging/logging.dart';

class Configuration extends BaseConfiguration {
  Configuration._privateConstructor();
  static final Configuration instance = Configuration._privateConstructor();
  static final _logger = Logger("Configuration");

  @override
  // Provide all secure storage keys that should be wiped on logout.
  // Locker app uses the standard keys defined in BaseConfiguration.
  List<String> get secureStorageKeys => [
        BaseConfiguration.keyKey,
        BaseConfiguration.secretKeyKey,
      ];

  @override
  Future<void> logout({bool autoLogout = false}) async {
    CollectionService.instance.clearCache();
    FavoritesService.instance.clearCache();

    await super.logout(autoLogout: autoLogout);
    await _clearCachedFiles();
  }

  Future<void> _clearCachedFiles() async {
    try {
      final cacheDir = Directory(getCacheDirectory());
      if (!await cacheDir.exists()) return;
      await for (final entity in cacheDir.list(followLinks: false)) {
        await entity.delete(recursive: true);
      }
    } catch (e, s) {
      _logger.warning("Failed to clear cached files on logout", e, s);
    }
  }
}
