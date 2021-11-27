import 'package:logging/logging.dart';

class AppLifecycleService {
  final _logger = Logger("AppLifecycleService");

  bool isForeground = false;

  static final AppLifecycleService instance =
      AppLifecycleService._privateConstructor();

  AppLifecycleService._privateConstructor();

  void onAppInForeground() {
    _logger.info("App in foreground");
    isForeground = true;
  }

  void onAppInBackground() {
    _logger.info("App in background");
    isForeground = false;
  }
}
