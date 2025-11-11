import 'dart:io';

import 'package:dbus_secrets/dbus_secrets.dart';
import 'package:ente_logging/logging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage_interface.dart';

SecureStorage createSecureStorageImpl() {
  if (Platform.isLinux) {
    return _LinuxSecureStorage();
  }
  return _FlutterSecureStorageAdapter();
}

class _FlutterSecureStorageAdapter implements SecureStorage {
  _FlutterSecureStorageAdapter()
      : _delegate = const FlutterSecureStorage(
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  final FlutterSecureStorage _delegate;

  @override
  Future<bool> containsKey({required String key}) {
    return _delegate.containsKey(key: key);
  }

  @override
  Future<void> delete({required String key}) {
    return _delegate.delete(key: key);
  }

  @override
  Future<String?> read({required String key}) {
    return _delegate.read(key: key);
  }

  @override
  Future<void> write({required String key, String? value}) {
    return _delegate.write(key: key, value: value);
  }
}

class _LinuxSecureStorage implements SecureStorage {
  _LinuxSecureStorage({DBusSecrets? client})
      : _client = client ??
            DBusSecrets(
              appName: 'ente_auth',
            );

  final DBusSecrets _client;
  final Logger _logger = Logger('LinuxSecureStorage');
  Future<void>? _initFuture;

  Future<void> _ensureReady() {
    return _initFuture ??= () async {
      final initialized = await _client.initialize();
      if (!initialized) {
        throw SecureStorageException('Failed to initialize DBus secrets');
      }
      final unlocked = await _client.unlock();
      if (!unlocked) {
        throw SecureStorageException(
          'Failed to unlock the default secrets collection',
        );
      }
    }();
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return (await read(key: key)) != null;
  }

  @override
  Future<void> delete({required String key}) async {
    await _ensureReady();
    final success = await _client.delete(key);
    if (!success) {
      _logger.warning('Failed to delete key "$key" from DBus secrets');
    }
  }

  @override
  Future<String?> read({required String key}) async {
    await _ensureReady();
    return _client.get(key);
  }

  @override
  Future<void> write({required String key, String? value}) async {
    await _ensureReady();
    if (value == null) {
      await delete(key: key);
      return;
    }

    final success = await _client.set(key, value);
    if (!success) {
      throw SecureStorageException(
          'Failed to store key "$key" in DBus secrets');
    }
  }
}
