import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import 'package:photos/services/sync_service.dart';

class PushService {
  static final PushService instance = PushService._privateConstructor();
  static final _logger = Logger("PushService");

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
    _logger.info("token " + await FirebaseMessaging.instance.getToken());
    _logger
        .info("APNS token " + await FirebaseMessaging.instance.getAPNSToken());
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _logger.info('init complete');
  }
}

final _logger = Logger("PushService");

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _logger.info("Handling a background message: ${message.messageId}");
  _handlePushMessage(message);
}

void _handlePushMessage(RemoteMessage message) {
  _logger.info('Message data: ${message.data}');
  if (message.notification != null) {
    _logger
        .info('Message also contained a notification: ${message.notification}');
  }
  if (message.data != null && message.data["purpose"] == "sync") {
    SyncService.instance.sync();
  }
}
