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
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
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
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    if (!hasGrantedPermissions() &&
        RemoteSyncService.instance.isFirstRemoteSyncDone()) {
      await requestPermissions();
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            sound: true,
            alert: true,
          );
      if (result != null) {
        _preferences.setBool(keyGrantedNotificationPermission, result);
      }
    } else {
      _preferences.setBool(keyGrantedNotificationPermission, true);
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

  Future<void> showNotification(String title, String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'io.ente.photos',
      'ente',
      channelDescription: 'ente alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      message,
      platformChannelSpecifics,
    );
  }
}
