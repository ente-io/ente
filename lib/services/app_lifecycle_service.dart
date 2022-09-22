import 'package:logging/logging.dart';

class AppLifecycleService {
  final _logger = Logger("AppLifecycleService");

  bool isForeground = false;

  static final AppLifecycleService instance =
      AppLifecycleService._privateConstructor();

  AppLifecycleService._privateConstructor();

  void onAppInForeground(String reason) {
    _logger.info("App in foreground via $reason");
    isForeground = true;
  }

  void onAppInBackground(String reason) {
    _logger.info("App in background $reason");
    isForeground = false;
  }
}
