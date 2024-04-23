import "package:dio/dio.dart";
import "package:ente_feature_flag/ente_feature_flag.dart";
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
