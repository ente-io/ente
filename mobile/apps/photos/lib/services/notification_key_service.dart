import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:photos/src/rust/api/notification_api.dart';
import 'package:photos/src/rust/frb_generated.dart';

class NotificationKeyService {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'notification_recipient';

  static Future<String?> generateNotificationKey() async {
    if (!Platform.isAndroid) return null;
    var pair = await getNotificationKeyPair();
    if (pair == null) {
      pair = generateNotificationKeyPair();
      await setNotificationKeyPair(pair);
    }
    return base64Encode(pair.publicKey);
  }

  static Future<Map<String, dynamic>?> decrypt(
    Map<String, dynamic> data,
  ) async {
    final pair = await getNotificationKeyPair();
    if (pair == null) return null;
    if (!EntePhotosRust.instance.initialized) {
      await EntePhotosRust.init();
    }
    final plaintext = decryptNotification(
      ciphertext: base64Decode(data['notificationCiphertext'] as String),
      privateKey: pair.privateKey,
    );
    final event = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    if (event['eventType'] is! String) return null;
    return event;
  }

  static Future<NotificationKeyPair?> getNotificationKeyPair() async {
    final encoded = await _storage.read(key: _storageKey);
    if (encoded == null) return null;
    final record = jsonDecode(encoded) as Map<String, dynamic>;
    return NotificationKeyPair(
      publicKey: base64Decode(record['publicKey'] as String),
      privateKey: base64Decode(record['privateKey'] as String),
    );
  }

  static Future<void> setNotificationKeyPair(NotificationKeyPair? pair) async {
    if (pair == null) {
      await _storage.delete(key: _storageKey);
    } else {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode({
          'publicKey': base64Encode(pair.publicKey),
          'privateKey': base64Encode(pair.privateKey),
        }),
      );
    }
  }
}
