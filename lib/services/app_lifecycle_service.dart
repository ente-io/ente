import 'package:logging/logging.dart';
import 'package:media_extension/media_extension_action_types.dart';

class AppLifecycleService {
  final _logger = Logger("AppLifecycleService");

  bool isForeground = false;
  IntentAction intentAction = IntentAction.main;

  static final AppLifecycleService instance =
      AppLifecycleService._privateConstructor();

  AppLifecycleService._privateConstructor();

  void setIntentAction(IntentAction intentAction) {
    this.intentAction = intentAction;
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
