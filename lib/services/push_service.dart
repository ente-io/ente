import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/events/signed_in_event.dart';
import 'package:photos/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushService {
  static const kFCMPushTokenKey = "fcm_push_token";

  static final PushService instance = PushService._privateConstructor();
  static final _logger = Logger("PushService");

  final _dio = Network.instance.getDio();

  SharedPreferences _prefs;

  PushService._privateConstructor();

  Future<void> init() async {
    await Firebase.initializeApp();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.info('Got a message whilst in the foreground!');
      _handlePushMessage(message);
    });
    if (Configuration.instance.hasConfiguredAccount()) {
      await _configurePushToken();
    } else {
      Bus.instance.on<SignedInEvent>().listen((_) {
        _configurePushToken();
      });
    }
  }

  Future<void> _configurePushToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (_prefs.getString(kFCMPushTokenKey) != fcmToken) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      await _setPushTokenOnServer(fcmToken, apnsToken);
      await _prefs.setString(kFCMPushTokenKey, fcmToken);
      _logger.info("Push token updated on server");
    }
  }

  Future<void> _setPushTokenOnServer(String fcmToken, String apnsToken) async {
    try {
      await _dio.post(
        Configuration.instance.getHttpEndpoint() + "/push/token",
        data: {
          "fcmToken": fcmToken,
          "apnsToken": apnsToken,
        },
        options: Options(
          headers: {
            "X-Auth-Token": Configuration.instance.getToken(),
          },
        ),
      );
    } catch (e, s) {
      _logger.severe(e, s);
      rethrow;
    }
  }

  void _handlePushMessage(RemoteMessage message) {
    _logger.info('Message data: ${message.data}');
    if (message.notification != null) {
      _logger.info(
          'Message also contained a notification: ${message.notification}');
    }
    SyncService.instance.sync();
  }
}
