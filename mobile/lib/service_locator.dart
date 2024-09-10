import "package:dio/dio.dart";
import "package:ente_cast/ente_cast.dart";
import "package:ente_cast_normal/ente_cast_normal.dart";
import "package:ente_feature_flag/ente_feature_flag.dart";
import "package:photos/utils/local_settings.dart";
import "package:shared_preferences/shared_preferences.dart";

class ServiceLocator {
  late final SharedPreferences prefs;
  late final Dio enteDio;

  // instance
  ServiceLocator._privateConstructor();

  static final ServiceLocator instance = ServiceLocator._privateConstructor();

  init(SharedPreferences prefs, Dio enteDio) {
    this.prefs = prefs;
    this.enteDio = enteDio;
  }
}

FlagService? _flagService;
FlagService get flagService {
  _flagService ??= FlagService(
    ServiceLocator.instance.prefs,
    ServiceLocator.instance.enteDio,
  );
  return _flagService!;
}

CastService? _castService;
CastService get castService {
  _castService ??= CastServiceImpl();
  return _castService!;
}

LocalSettings? _localSettings;
LocalSettings get localSettings {
  _localSettings ??= LocalSettings(ServiceLocator.instance.prefs);
  return _localSettings!;
}
