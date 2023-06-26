import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import "package:photos/services/remote_sync_service.dart";
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

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    const androidSettings = AndroidInitializationSettings('notification_icon');
    const iosSettings = DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(initializationSettings);
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
          ?.requestPermission();
    }
    if (result != null) {
      _preferences.setBool(keyGrantedNotificationPermission, result);
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
    String identifier = "io.ente.photos",
  }) async {
    final androidSpecs = AndroidNotificationDetails(
      identifier,
      'ente',
      channelDescription: 'ente alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    final iosSpecs = DarwinNotificationDetails(threadIdentifier: identifier);
    final platformChannelSpecs =
        NotificationDetails(android: androidSpecs, iOS: iosSpecs);
    await _notificationsPlugin.show(
      0,
      title,
      message,
      platformChannelSpecs,
    );
  }
}
