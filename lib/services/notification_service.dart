import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import "package:shared_preferences/shared_preferences.dart";

class NotificationService {
  static final NotificationService instance =
      NotificationService._privateConstructor();
  static const String keyGrantedNotificationPermission =
      "notification_permission_granted";
  static const String keyShouldShowNotifications = "notifications_enabled";

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
    if (!hasGrantedPermissions()) {
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
    }
  }

  bool hasGrantedPermissions() {
    if (Platform.isAndroid) {
      return true;
    }
    final result = _preferences.getBool(keyGrantedNotificationPermission);
    return result ?? false;
  }

  bool shouldShowNotifications() {
    final result = _preferences.getBool(keyShouldShowNotifications);
    return result ?? true;
  }

  Future<void> setShouldShowNotifications(bool value) {
    return _preferences.setBool(keyShouldShowNotifications, value);
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
