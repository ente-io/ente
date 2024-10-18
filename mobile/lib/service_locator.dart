import "package:dio/dio.dart";
import "package:ente_cast/ente_cast.dart";
import "package:ente_cast_normal/ente_cast_normal.dart";
import "package:ente_feature_flag/ente_feature_flag.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:photos/gateways/entity_gw.dart";
import "package:photos/services/entity_service.dart";
import "package:photos/services/storage_bonus_service.dart";
import "package:photos/services/update_service.dart";
import "package:photos/utils/local_settings.dart";
import "package:shared_preferences/shared_preferences.dart";

class ServiceLocator {
  late final SharedPreferences prefs;
  late final Dio enteDio;
  late final PackageInfo packageInfo;

  // instance
  ServiceLocator._privateConstructor();

  static final ServiceLocator instance = ServiceLocator._privateConstructor();

  init(SharedPreferences prefs, Dio enteDio, PackageInfo packageInfo) {
    this.prefs = prefs;
    this.enteDio = enteDio;
    this.packageInfo = packageInfo;
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

StorageBonusService? _storageBonusService;
StorageBonusService get storageBonusService {
  _storageBonusService ??= StorageBonusService(
    ServiceLocator.instance.prefs,
    ServiceLocator.instance.enteDio,
  );
  return _storageBonusService!;
}

UpdateService? _updateService;

UpdateService get updateService {
  _updateService ??= UpdateService(
    ServiceLocator.instance.prefs,
    ServiceLocator.instance.packageInfo,
  );
  return _updateService!;
}

EntityService? _entityService;

EntityService get entityService {
  _entityService ??= EntityService(
    ServiceLocator.instance.prefs,
    EntityGateway(ServiceLocator.instance.enteDio),
  );
  return _entityService!;
}
