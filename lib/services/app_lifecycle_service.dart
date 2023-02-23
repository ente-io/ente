import 'package:logging/logging.dart';
import 'package:media_extension/media_extension_action_types.dart';

class AppLifecycleService {
  final _logger = Logger("AppLifecycleService");

  bool isForeground = false;
  MediaExtentionAction mediaExtensionAction =
      MediaExtentionAction(action: IntentAction.main);

  static final AppLifecycleService instance =
      AppLifecycleService._privateConstructor();

  AppLifecycleService._privateConstructor();

  void setMediaExtensionAction(MediaExtentionAction mediaExtensionAction) {
    _logger.info("App invoked via ${mediaExtensionAction.action}");
    this.mediaExtensionAction = mediaExtensionAction;
  }

  void onAppInForeground(String reason) {
    _logger.info("App in foreground via $reason");
    isForeground = true;
  }

  void onAppInBackground(String reason) {
    _logger.info("App in background $reason");
    isForeground = false;
  }
}
