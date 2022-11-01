import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/errors.dart';
import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/core/network.dart';
import 'package:ente_auth/events/codes_updated_event.dart';
import 'package:ente_auth/events/signed_in_event.dart';
import 'package:ente_auth/gateway/authenticator.dart';
import 'package:ente_auth/models/authenticator/auth_entity.dart';
import 'package:ente_auth/models/authenticator/auth_key.dart';
import 'package:ente_auth/models/authenticator/local_auth_entity.dart';
import 'package:ente_auth/store/authenticator_db.dart';
import 'package:ente_auth/utils/crypto_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticatorService {
  final _logger = Logger((AuthenticatorService).toString());
  final _config = Configuration.instance;
  late SharedPreferences _prefs;
  late AuthenticatorGateway _gateway;
  late AuthenticatorDB _db;
  final String _lastEntitySyncTime = "lastEntitySyncTime";

  AuthenticatorService._privateConstructor();

  static final AuthenticatorService instance =
      AuthenticatorService._privateConstructor();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _db = AuthenticatorDB.instance;
    _gateway = AuthenticatorGateway(Network.instance.getDio(), _config);
    if (Configuration.instance.hasConfiguredAccount()) {
      unawaited(sync());
    }
    Bus.instance.on<SignedInEvent>().listen((event) {
      unawaited(sync());
    });
  }

  Future<Map<int, String>> getAllIDtoStringMap() async {
    final List<LocalAuthEntity> result = await _db.getAll();
    final Map<int, String> entries = <int, String>{};
    if (result.isEmpty) {
      return entries;
    }
    final key = await getOrCreateAuthDataKey();
    for (LocalAuthEntity e in result) {
      final decryptedValue = await CryptoUtil.decryptChaCha(
        Sodium.base642bin(e.encryptedData),
        key,
        Sodium.base642bin(e.header),
      );
      entries[e.generatedID] = utf8.decode(decryptedValue);
    }
    return entries;
  }

  Future<int> addEntry(String plainText) async {
    var key = await getOrCreateAuthDataKey();
    final encryptedKeyData = await CryptoUtil.encryptChaCha(
      utf8.encode(plainText) as Uint8List,
      key,
    );
    String encryptedData = Sodium.bin2base64(encryptedKeyData.encryptedData!);
    String header = Sodium.bin2base64(encryptedKeyData.header!);
    final insertedID = await _db.insert(encryptedData, header);
    unawaited(sync());
    return insertedID;
  }

  Future<void> updateEntry(int generatedID, String plainText) async {
    var key = await getOrCreateAuthDataKey();
    final encryptedKeyData = await CryptoUtil.encryptChaCha(
      utf8.encode(plainText) as Uint8List,
      key,
    );
    String encryptedData = Sodium.bin2base64(encryptedKeyData.encryptedData!);
    String header = Sodium.bin2base64(encryptedKeyData.header!);
    final int affectedRows =
        await _db.updateEntry(generatedID, encryptedData, header);
    assert(
      affectedRows == 1,
      "updateEntry should have updated exactly one row",
    );
    unawaited(sync());
  }

  Future<void> deleteEntry(int genID) async {
    LocalAuthEntity? result = await _db.getEntryByID(genID);
    if (result == null) {
      _logger.info("No entry found for given id");
      return;
    }
    if (result.id != null) {
      await _gateway.deleteEntity(result.id!);
    }
    await _db.deleteByIDs(generatedIDs: [genID]);
  }

  Future<void> sync() async {
    try {
      _logger.info("Sync");
      _logger.info("State of DB before sync");
      await _printDBState();
      await _remoteToLocalSync();
      _logger.info("remote fetch completed");
      _logger.info("State of DB after remoteToLocal sync");
      await _printDBState();
      await _localToRemoteSync();
      _logger.info("State of DB after localToRemote sync");
      await _printDBState();
      _logger.info("local push completed");
      Bus.instance.fire(CodesUpdatedEvent());
    } catch (e) {
      _logger.severe("Failed to sync with remote", e);
    }
  }

  Future<void> _remoteToLocalSync() async {
    _logger.info('Initiating remote to local sync');
    final int lastSyncTime = _prefs.getInt(_lastEntitySyncTime) ?? 0;
    const int fetchLimit = 500;
    final List<AuthEntity> result =
        await _gateway.getDiff(lastSyncTime, limit: fetchLimit);
    if (result.isEmpty) {
      return;
    } else {
      _logger.info(result.length.toString() + " entries fetched from remote");
    }
    final maxSyncTime = result.map((e) => e.updatedAt).reduce(max);
    List<String> deletedIDs =
        result.where((element) => element.isDeleted).map((e) => e.id).toList();
    result.removeWhere((element) => element.isDeleted);
    await _db.insertOrReplace(result);
    if (deletedIDs.isNotEmpty) {
      await _db.deleteByIDs(ids: deletedIDs);
    }
    _prefs.setInt(_lastEntitySyncTime, maxSyncTime);
    if (result.length == fetchLimit) {
      await _remoteToLocalSync();
    }
  }

  Future<void> _localToRemoteSync() async {
    _logger.info('Initiating local to remote sync');
    final List<LocalAuthEntity> result = await _db.getAll();
    final List<LocalAuthEntity> pendingUpdate = result
        .where((element) => element.shouldSync || element.id == null)
        .toList();
    _logger.info(
      pendingUpdate.length.toString() + " entries to be updated at remote",
    );
    for (LocalAuthEntity entity in pendingUpdate) {
      if (entity.id == null) {
        _logger.info("Adding new entry");
        final authEntity =
            await _gateway.createEntity(entity.encryptedData, entity.header);
        await _db.updateLocalEntity(
          entity.copyWith(
            id: authEntity.id,
            shouldSync: false,
          ),
        );
      } else {
        _logger.info("Updating entry");
        await _gateway.updateEntity(
          entity.id!,
          entity.encryptedData,
          entity.header,
        );
        await _db.updateLocalEntity(entity.copyWith(shouldSync: false));
      }
    }
  }

  Future<Uint8List> getOrCreateAuthDataKey() async {
    if (_config.getAuthSecretKey() != null) {
      return _config.getAuthSecretKey()!;
    }
    try {
      final AuthKey response = await _gateway.getKey();
      final authKey = CryptoUtil.decryptSync(
        Sodium.base642bin(response.encryptedKey),
        _config.getKey(),
        Sodium.base642bin(response.header),
      );
      await _config.setAuthSecretKey(Sodium.bin2base64(authKey));
      return authKey;
    } on AuthenticatorKeyNotFound catch (e) {
      _logger.info("AuthenticatorKeyNotFound generating key ${e.stackTrace}");
      final key = CryptoUtil.generateKey();
      final encryptedKeyData = CryptoUtil.encryptSync(key, _config.getKey()!);
      await _gateway.createKey(
        Sodium.bin2base64(encryptedKeyData.encryptedData!),
        Sodium.bin2base64(encryptedKeyData.nonce!),
      );
      await _config.setAuthSecretKey(Sodium.bin2base64(key));
      return key;
    } catch (e, s) {
      _logger.severe("Failed to getOrCreateAuthDataKey", e, s);
      rethrow;
    }
  }

  Future<void> _printDBState() async {
    _logger.info("_____");
    final entities = await _db.getAll();
    for (final entity in entities) {
      _logger.info(entity.id);
    }
    _logger.info("_____");
  }
}
