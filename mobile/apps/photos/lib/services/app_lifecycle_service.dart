import "dart:async";

import 'package:logging/logging.dart';
import 'package:media_extension/media_extension_action_types.dart';
import "package:photos/services/upload_background_coordinator.dart";
import "package:shared_preferences/shared_preferences.dart";

class AppLifecycleService {
  static const String keyLastAppOpenTime = "last_app_open_time";

  final _logger = Logger("AppLifecycleService");

  bool isForeground = false;
  MediaExtentionAction mediaExtensionAction =
      MediaExtentionAction(action: IntentAction.main);
  late SharedPreferences _preferences;

  static final AppLifecycleService instance =
      AppLifecycleService._privateConstructor();

  AppLifecycleService._privateConstructor();

  void init(SharedPreferences preferences) {
    _preferences = preferences;
  }

  void setMediaExtensionAction(MediaExtentionAction mediaExtensionAction) {
    _logger.info("App invoked via ${mediaExtensionAction.action}");
    this.mediaExtensionAction = mediaExtensionAction;
  }

  void onAppInForeground(String reason) {
    _logger.info("App in foreground via $reason");
    final wasForeground = isForeground;
    isForeground = true;
    if (!wasForeground) {
      unawaited(UploadBackgroundCoordinator.instance.onAppForeground());
    }
  }

  void onAppInBackground(String reason) {
    _logger.info("App in background $reason");
    if (isForeground) {
      _preferences.setInt(
        keyLastAppOpenTime,
        DateTime.now().microsecondsSinceEpoch,
      );
      unawaited(UploadBackgroundCoordinator.instance.onAppBackground());
    } else {
      _logger.info("App already in background, skipping open time update");
    }
    isForeground = false;
  }

  int getLastAppOpenTime() {
    return _preferences.getInt(keyLastAppOpenTime) ?? 0;
  }
}
