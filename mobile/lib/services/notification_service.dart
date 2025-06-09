import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import "package:flutter_timezone/flutter_timezone.dart";
import "package:logging/logging.dart";
import "package:photos/services/sync/remote_sync_service.dart";
import "package:shared_preferences/shared_preferences.dart";
import 'package:timezone/data/latest_10y.dart' as tzdb;
import "package:timezone/timezone.dart" as tz;

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

  bool timezoneInitialized = false;

  Future<void> initialize(
    void Function(
      NotificationResponse notificationResponse,
    ) onNotificationTapped,
  ) async {
    await initTimezones();
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

  Future<void> initTimezones() async {
    if (timezoneInitialized) return;
    tzdb.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
    timezoneInitialized = true;
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

  Future<void> scheduleNotification(
    String title, {
    String? message,
    required int id,
    String channelID = "io.ente.photos",
    String channelName = "ente",
    String payload = "ente://home",
    required DateTime dateTime,
    Duration? timeoutDurationAndroid,
  }) async {
    try {
      _logger.info(
        "Scheduling notification with: $title, $message, $channelID, $channelName, $payload",
      );
      await initTimezones();
      if (!hasGrantedPermissions()) {
        _logger.warning("Notification permissions not granted");
        await requestPermissions();
        if (!hasGrantedPermissions()) {
          _logger.severe("Failed to get notification permissions");
          return;
        }
      } else {
        _logger.info("Notification permissions already granted");
      }
      final androidSpecs = AndroidNotificationDetails(
        channelID,
        channelName,
        channelDescription: 'ente alerts',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        showWhen: false,
      );
      final iosSpecs = DarwinNotificationDetails(threadIdentifier: channelID);
      final platformChannelSpecs =
          NotificationDetails(android: androidSpecs, iOS: iosSpecs);
      final scheduledDate = tz.TZDateTime.local(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
      );
      // final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        message,
        scheduledDate,
        platformChannelSpecs,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      _logger.info(
        "Scheduled notification with: $title, $message, $channelID, $channelName, $payload for $dateTime",
      );
    } catch (e, s) {
      // For now we're swallowing any exceptions here because we don't want the memories logic to get disturbed
      _logger.severe(
        "Something went wrong while scheduling notification",
        e,
        s,
      );
    }
    final androidSpecs = AndroidNotificationDetails(
      channelID,
      channelName,
      channelDescription: 'ente alerts',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      showWhen: false,
      timeoutAfter: timeoutDurationAndroid?.inMilliseconds,
    );
    final iosSpecs = DarwinNotificationDetails(threadIdentifier: channelID);
    final platformChannelSpecs =
        NotificationDetails(android: androidSpecs, iOS: iosSpecs);
    final scheduledDate = tz.TZDateTime.local(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      message,
      scheduledDate,
      platformChannelSpecs,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
    _logger.info(
      "Scheduled notification with: $title, $message, $channelID, $channelName, $payload",
    );
  }

  Future<void> clearAllScheduledNotifications({
    String? containingPayload,
  }) async {
    try {
      _logger.info("Clearing all scheduled notifications");
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      if (pending.isEmpty) {
        _logger.info("No pending notifications to clear");
        return;
      }
      for (final request in pending) {
        if (containingPayload != null &&
            !request.payload.toString().contains(containingPayload)) {
          _logger.info(
            "Skip clearing of notification with id: ${request.id} and payload: ${request.payload}",
          );
          continue;
        }
        _logger.info(
          "Clearing notification with id: ${request.id} and payload: ${request.payload}",
        );
        await _notificationsPlugin.cancel(request.id);
        _logger.info(
          "Cleared notification with id: ${request.id} and payload: ${request.payload}",
        );
      }
    } catch (e, s) {
      _logger.severe("Something is wrong with scheduled notifications", e, s);
    }
  }

  Future<int> pendingNotifications() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    return pending.length;
  }
}
