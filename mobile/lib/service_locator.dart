import "package:dio/dio.dart";
import "package:ente_cast/ente_cast.dart";
import "package:ente_cast_normal/ente_cast_normal.dart";
import "package:ente_feature_flag/ente_feature_flag.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:photos/gateways/entity_gw.dart";
import "package:photos/services/billing_service.dart";
import "package:photos/services/entity_service.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/machine_learning/face_ml/face_recognition_service.dart";
import "package:photos/services/machine_learning/machine_learning_controller.dart";
import "package:photos/services/magic_cache_service.dart";
import "package:photos/services/storage_bonus_service.dart";
import "package:photos/services/trash_sync_service.dart";
import "package:photos/services/update_service.dart";
import "package:photos/services/user_remote_flag_service.dart";
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

TrashSyncService? _trashSyncService;
TrashSyncService get trashSyncService {
  _trashSyncService ??= TrashSyncService(
    ServiceLocator.instance.prefs,
    ServiceLocator.instance.enteDio,
  );
  return _trashSyncService!;
}

LocationService? _locationService;
LocationService get locationService {
  _locationService ??= LocationService(ServiceLocator.instance.prefs);
  return _locationService!;
}

UserRemoteFlagService? _userRemoteFlagService;
UserRemoteFlagService get userRemoteFlagService {
  _userRemoteFlagService ??= UserRemoteFlagService(
    ServiceLocator.instance.enteDio,
    ServiceLocator.instance.prefs,
  );
  return _userRemoteFlagService!;
}

MagicCacheService? _magicCacheService;
MagicCacheService get magicCacheService {
  _magicCacheService ??= MagicCacheService(
    ServiceLocator.instance.prefs,
  );
  return _magicCacheService!;
}

BillingService? _billingService;
BillingService get billingService {
  _billingService ??= BillingService(
    ServiceLocator.instance.enteDio,
  );
  return _billingService!;
}

MachineLearningController? _machineLearningController;
MachineLearningController get machineLearningController {
  _machineLearningController ??= MachineLearningController();
  return _machineLearningController!;
}

FaceRecognitionService? _faceRecognitionService;
FaceRecognitionService get faceRecognitionService {
  _faceRecognitionService ??= FaceRecognitionService();
  return _faceRecognitionService!;
}
