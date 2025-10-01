import 'dart:async';
import 'dart:typed_data';

import 'package:ente_base/models/database.dart';
import 'package:ente_configuration/base_configuration.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Configuration extends BaseConfiguration {
  Configuration._privateConstructor();

  static final Configuration instance = Configuration._privateConstructor();
  static const authSecretKeyKey = "auth_secret_key";
  static const offlineAuthSecretKey = "offline_auth_secret_key";
  static const hasOptedForOfflineModeKey = "has_opted_for_offline_mode";

  late SharedPreferences _preferences;
  String? _authSecretKey;
  String? _offlineAuthKey;
  late FlutterSecureStorage _secureStorage;

  @override
  Future<void> init(List<EnteBaseDatabase> dbs) async {
    await super.init(dbs);
    _preferences = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    sqfliteFfiInit();
    await _initOfflineAccount();
  }

  Future<void> _initOfflineAccount() async {
    _offlineAuthKey = await _secureStorage.read(
      key: offlineAuthSecretKey,
    );
  }

  @override
  Future<void> logout({bool autoLogout = false}) async {
    _authSecretKey = null;
    await super.logout();
  }

  Future<void> setAuthSecretKey(String? authSecretKey) async {
    _authSecretKey = authSecretKey;
    await _secureStorage.write(
      key: authSecretKeyKey,
      value: authSecretKey,
    );
  }

  Uint8List? getAuthSecretKey() {
    return _authSecretKey == null
        ? null
        : CryptoUtil.base642bin(_authSecretKey!);
  }

  Uint8List? getOfflineSecretKey() {
    return _offlineAuthKey == null
        ? null
        : CryptoUtil.base642bin(_offlineAuthKey!);
  }

  bool hasOptedForOfflineMode() {
    return _preferences.getBool(hasOptedForOfflineModeKey) ?? false;
  }

  Future<void> optForOfflineMode() async {
    if ((await _secureStorage.containsKey(
      key: offlineAuthSecretKey,
    ))) {
      _offlineAuthKey = await _secureStorage.read(
        key: offlineAuthSecretKey,
      );
    } else {
      _offlineAuthKey = CryptoUtil.bin2base64(CryptoUtil.generateKey());
      await _secureStorage.write(
        key: offlineAuthSecretKey,
        value: _offlineAuthKey,
      );
    }
    await _preferences.setBool(hasOptedForOfflineModeKey, true);
  }
}
