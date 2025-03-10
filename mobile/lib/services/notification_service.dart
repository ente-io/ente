import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import "package:logging/logging.dart";
import "package:photos/services/sync/remote_sync_service.dart";
import "package:shared_preferences/shared_preferences.dart";

class NotificationService {
  static final NotificationService instance =
      NotificationService._privateConstructor();
  static const String keyGrantedNotificationPermission =
      "notification_permission_granted";
  static const String keyShouldShowNotificationsForSharedPhotos =
      "notifications_enabled_shared_photos";

  NotificationService._privateConstructor();

  late SharedPreferences _preferences;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _logger = Logger("NotificationService");

  void init(SharedPreferences preferences) {
    _preferences = preferences;
  }

  Future<void> initialize(
    void Function(
      NotificationResponse notificationResponse,
    ) onNotificationTapped,
  ) async {
    const androidSettings = AndroidInitializationSettings('notification_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestCriticalPermission: false,
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTapped,
    );

    final launchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      onNotificationTapped(launchDetails.notificationResponse!);
    }
    if (!hasGrantedPermissions() &&
        RemoteSyncService.instance.isFirstRemoteSyncDone()) {
      await requestPermissions();
    }
  }

  Future<void> requestPermissions() async {
    bool? result;
    if (Platform.isIOS) {
      result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            sound: true,
            alert: true,
          );
    } else {
      result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    if (result != null) {
      await _preferences.setBool(keyGrantedNotificationPermission, result);
    }
  }

  bool hasGrantedPermissions() {
    final result = _preferences.getBool(keyGrantedNotificationPermission);
    return result ?? false;
  }

  bool shouldShowNotificationsForSharedPhotos() {
    final result =
        _preferences.getBool(keyShouldShowNotificationsForSharedPhotos);
    return result ?? true;
  }

  Future<void> setShouldShowNotificationsForSharedPhotos(bool value) {
    return _preferences.setBool(
      keyShouldShowNotificationsForSharedPhotos,
      value,
    );
  }

  Future<void> showNotification(
    String title,
    String message, {
    String channelID = "io.ente.photos",
    String channelName = "ente",
    String payload = "ente://home",
  }) async {
    _logger.info(
      "Showing notification with: $title, $message, $channelID, $channelName, $payload",
    );
    final androidSpecs = AndroidNotificationDetails(
      channelID,
      channelName,
      channelDescription: 'ente alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    final iosSpecs = DarwinNotificationDetails(threadIdentifier: channelID);
    final platformChannelSpecs =
        NotificationDetails(android: androidSpecs, iOS: iosSpecs);
    await _notificationsPlugin.show(
      channelName.hashCode,
      title,
      message,
      platformChannelSpecs,
      payload: payload,
    );
  }
}
