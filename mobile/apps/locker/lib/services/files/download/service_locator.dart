import 'package:dio/dio.dart';
import 'package:locker/services/files/download/manager.dart';
import "package:locker/utils/local_settings.dart";
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceLocator {
  late final SharedPreferences prefs;
  late final Dio enteDio;
  late final Dio nonEnteDio;
  late final PackageInfo packageInfo;

  // instance
  ServiceLocator._privateConstructor();

  static final ServiceLocator instance = ServiceLocator._privateConstructor();

  init(
    SharedPreferences prefs,
    Dio enteDio,
    Dio nonEnteDio,
    PackageInfo packageInfo,
  ) {
    this.prefs = prefs;
    this.enteDio = enteDio;
    this.nonEnteDio = nonEnteDio;
    this.packageInfo = packageInfo;
  }
}

DownloadManager? _downloadManager;
DownloadManager get downloadManager {
  _downloadManager ??= DownloadManager(
    ServiceLocator.instance.nonEnteDio,
  );
  return _downloadManager!;
}

LocalSettings? _localSettings;
LocalSettings get localSettings {
  _localSettings ??= LocalSettings(ServiceLocator.instance.prefs);
  return _localSettings!;
}
