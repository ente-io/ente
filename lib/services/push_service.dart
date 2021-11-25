import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/events/signed_in_event.dart';
import 'package:photos/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushService {
  static const kFCMPushToken = "fcm_push_token";
  static const kLastFCMTokenUpdationTime = "fcm_push_token_updation_time";
  static const kFCMTokenUpdationIntervalInMicroSeconds =
      30 * kMicroSecondsInDay;
  static const kPushAction = "action";
  static const kSync = "sync";

  static final PushService instance = PushService._privateConstructor();
  static final _logger = Logger("PushService");

  final _dio = Network.instance.getDio();

  SharedPreferences _prefs;

  PushService._privateConstructor();

  Future<void> init() async {
    if (!Platform.isIOS) {
      return;
    }
    _prefs = await SharedPreferences.getInstance();
    await Firebase.initializeApp();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.info("Got a message whilst in the foreground!");
      _handleForegroundPushMessage(message);
    });
    if (Configuration.instance.hasConfiguredAccount()) {
      await _requestPermission(messaging);
      await _configurePushToken();
    } else {
      Bus.instance.on<SignedInEvent>().listen((_) async {
        await _requestPermission(messaging);
        _configurePushToken();
      });
    }
  }

  Future<void> _requestPermission(FirebaseMessaging messaging) async {
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> _configurePushToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final shouldForceRefreshServerToken =
        DateTime.now().microsecondsSinceEpoch -
                (_prefs.getInt(kLastFCMTokenUpdationTime) ?? 0) >
            kFCMTokenUpdationIntervalInMicroSeconds;
    if (_prefs.getString(fcmToken) != fcmToken ||
        shouldForceRefreshServerToken) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      try {
        _logger.info("Updating token on server");
        await _setPushTokenOnServer(fcmToken, apnsToken);
        await _prefs.setString(kFCMPushToken, fcmToken);
        await _prefs.setInt(
            kLastFCMTokenUpdationTime, DateTime.now().microsecondsSinceEpoch);
        _logger.info("Push token updated on server");
      } catch (e) {
        _logger.severe("Could not set push token", e, StackTrace.current);
      }
    } else {
      _logger.info("Skipping token update");
    }
  }

  Future<void> _setPushTokenOnServer(String fcmToken, String apnsToken) async {
    await _dio.post(
      Configuration.instance.getHttpEndpoint() + "/push/token",
      data: {
        "fcmToken": fcmToken,
        "apnsToken": apnsToken,
      },
      options: Options(
        headers: {"X-Auth-Token": Configuration.instance.getToken()},
      ),
    );
  }

  void _handleForegroundPushMessage(RemoteMessage message) {
    _logger.info("Message data: ${message.data}");
    if (message.notification != null) {
      _logger.info(
          "Message also contained a notification: ${message.notification}");
    }
    if (shouldSync(message)) {
      SyncService.instance.sync();
    }
  }

  static bool shouldSync(RemoteMessage message) {
    return message.data.containsKey(kPushAction) &&
        message.data[kPushAction] == kSync;
  }
}
