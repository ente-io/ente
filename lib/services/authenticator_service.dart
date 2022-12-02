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
import 'package:ente_auth/models/authenticator/entity_result.dart';
import 'package:ente_auth/models/authenticator/local_auth_entity.dart';
import 'package:ente_auth/store/authenticator_db.dart';
import 'package:ente_auth/utils/crypto_util.dart';
import 'package:flutter/foundation.dart';
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

  Future<List<EntityResult>> getEntities() async {
    final List<LocalAuthEntity> result = await _db.getAll();
    final List<EntityResult> entities = [];
    if (result.isEmpty) {
      return entities;
    }
    final key = await getOrCreateAuthDataKey();
    for (LocalAuthEntity e in result) {
      try {
        final decryptedValue = await CryptoUtil.decryptChaCha(
          base64.decode(e.encryptedData),
          key,
          base64.decode(e.header),
        );
        final hasSynced = !(e.id == null || e.shouldSync);
        entities.add(
          EntityResult(
            e.generatedID,
            utf8.decode(decryptedValue),
            hasSynced,
          ),
        );
      } catch (e, s) {
        _logger.severe(e, s);
      }
    }
    return entities;
  }

  Future<int> addEntry(String plainText, bool shouldSync) async {
    var key = await getOrCreateAuthDataKey();
    final encryptedKeyData = await CryptoUtil.encryptChaCha(
      utf8.encode(plainText) as Uint8List,
      key,
    );
    String encryptedData = base64Encode(encryptedKeyData.encryptedData!);
    String header = base64Encode(encryptedKeyData.header!);
    final insertedID = await _db.insert(encryptedData, header);
    if (shouldSync) {
      unawaited(sync());
    }
    return insertedID;
  }

  Future<void> updateEntry(
    int generatedID,
    String plainText,
    bool shouldSync,
  ) async {
    var key = await getOrCreateAuthDataKey();
    final encryptedKeyData = await CryptoUtil.encryptChaCha(
      utf8.encode(plainText) as Uint8List,
      key,
    );
    String encryptedData = base64Encode(encryptedKeyData.encryptedData!);
    String header = base64Encode(encryptedKeyData.header!);
    final int affectedRows =
        await _db.updateEntry(generatedID, encryptedData, header);
    assert(
      affectedRows == 1,
      "updateEntry should have updated exactly one row",
    );
    if (shouldSync) {
      unawaited(sync());
    }
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
      await _remoteToLocalSync();
      _logger.info("remote fetch completed");
      await _localToRemoteSync();
      _logger.info("local push completed");
      Bus.instance.fire(CodesUpdatedEvent());
    } catch (e) {
      _logger.severe("Failed to sync with remote", e);
    }
  }

  Future<void> _remoteToLocalSync() async {
    _logger.info('Initiating remote to local sync');
    final int lastSyncTime = _prefs.getInt(_lastEntitySyncTime) ?? 0;
    _logger.info("Current synctime is " + lastSyncTime.toString());
    const int fetchLimit = 500;
    final List<AuthEntity> result =
        await _gateway.getDiff(lastSyncTime, limit: fetchLimit);
    _logger.info(result.length.toString() + " entries fetched from remote");
    if (result.isEmpty) {
      return;
    }
    final maxSyncTime = result.map((e) => e.updatedAt).reduce(max);
    List<String> deletedIDs =
        result.where((element) => element.isDeleted).map((e) => e.id).toList();
    _logger.info(deletedIDs.length.toString() + " entries deleted");
    result.removeWhere((element) => element.isDeleted);
    await _db.insertOrReplace(result);
    if (deletedIDs.isNotEmpty) {
      await _db.deleteByIDs(ids: deletedIDs);
    }
    _prefs.setInt(_lastEntitySyncTime, maxSyncTime);
    _logger.info("Setting synctime to " + maxSyncTime.toString());
    if (result.length == fetchLimit) {
      _logger.info("Diff limit reached, pulling again");
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
    if (pendingUpdate.isNotEmpty) {
      _logger.info("Initiating remote sync since local entries were pushed");
      await _remoteToLocalSync();
    }
  }

  Future<Uint8List> getOrCreateAuthDataKey() async {
    if (_config.getAuthSecretKey() != null) {
      return _config.getAuthSecretKey()!;
    }
    try {
      final AuthKey response = await _gateway.getKey();
      final authKey = await CryptoUtil.decrypt(
        base64.decode(response.encryptedKey),
        _config.getKey()!,
        base64.decode(response.header),
      );
      await _config.setAuthSecretKey(base64Encode(authKey));
      return authKey;
    } on AuthenticatorKeyNotFound catch (e) {
      _logger.info("AuthenticatorKeyNotFound generating key ${e.stackTrace}");
      final key = CryptoUtil.generateKey();
      final encryptedKeyData = await CryptoUtil.encrypt(key, _config.getKey()!);
      await _gateway.createKey(
        base64Encode(encryptedKeyData.encryptedData!),
        base64Encode(encryptedKeyData.nonce!),
      );
      await _config.setAuthSecretKey(base64Encode(key));
      return key;
    } catch (e, s) {
      _logger.severe("Failed to getOrCreateAuthDataKey", e, s);
      rethrow;
    }
  }
}
