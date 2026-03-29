import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _logger = Logger('BackupExclusion');
const _channel = MethodChannel('io.ente.backup_exclusion');

/// Marks [path] as excluded from iCloud and local backups on iOS.
///
/// Called on every app init rather than once, so the flag is re-applied after
/// device restores (where directories are recreated without the attribute).
/// The syscall is idempotent and has negligible overhead.
///
/// No-op on non-iOS platforms.
Future<void> excludeFromBackup(String path) async {
  if (!Platform.isIOS) return;
  await _invokeExcludeFromBackup(path);
}

/// Invokes the platform channel directly, without the iOS platform guard.
///
/// Exposed for unit testing so tests can exercise the channel logic and
/// logging behaviour without needing to fake [Platform.isIOS].
@visibleForTesting
Future<void> invokeExcludeFromBackup(String path) =>
    _invokeExcludeFromBackup(path);

Future<void> _invokeExcludeFromBackup(String path) async {
  try {
    final ok = await _channel.invokeMethod<bool>('excludeFromBackup', {
      'path': path,
    });
    if (ok != true) {
      _logger.warning('excludeFromBackup returned false for: $path');
    }
  } on PlatformException catch (e) {
    _logger.warning('Failed to exclude path from backup: $path - ${e.message}');
  } on MissingPluginException {
    // Channel not registered in headless background execution (Workmanager).
    // Safe to ignore: backup exclusion is a best-effort attribute set on
    // foreground init; background tasks do not trigger iCloud backups.
    _logger.info('excludeFromBackup skipped: channel unavailable (background)');
  }
}
