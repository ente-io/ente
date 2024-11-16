import 'dart:async';
import 'dart:io';

import 'package:ente_auth/core/constants.dart';
import 'package:ente_auth/core/network.dart';
import 'package:ente_auth/services/notification_service.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher_string.dart';

class UpdateService {
  UpdateService._privateConstructor();

  static final UpdateService instance = UpdateService._privateConstructor();
  static const kUpdateAvailableShownTimeKey = "update_available_shown_time_key";
  static const String flavor = String.fromEnvironment('app.flavor');

  LatestVersionInfo? _latestVersion;
  final _logger = Logger("UpdateService");
  late PackageInfo _packageInfo;
  late SharedPreferences _prefs;

  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> shouldUpdate() async {
    if (!isIndependent()) {
      return false;
    }
    try {
      _latestVersion = await _getLatestVersionInfo();
      final currentVersionCode = int.parse(_packageInfo.buildNumber);
      return currentVersionCode < _latestVersion!.code!;
    } catch (e) {
      _logger.severe(e);
      return false;
    }
  }

  bool shouldForceUpdate(LatestVersionInfo? info) {
    if (!isIndependent()) {
      return false;
    }
    try {
      final currentVersionCode = int.parse(_packageInfo.buildNumber);
      return currentVersionCode < info!.lastSupportedVersionCode;
    } catch (e) {
      _logger.severe(e);
      return false;
    }
  }

  LatestVersionInfo? getLatestVersionInfo() {
    return _latestVersion;
  }

  Future<void> showUpdateNotification() async {
    if (!isIndependent()) {
      return;
    }
    final shouldUpdate = await this.shouldUpdate();
    final lastNotificationShownTime =
        _prefs.getInt(kUpdateAvailableShownTimeKey) ?? 0;
    final now = DateTime.now().microsecondsSinceEpoch;
    final hasBeen3DaysSinceLastNotification =
        (now - lastNotificationShownTime) > (3 * microSecondsInDay);
    if (shouldUpdate &&
        hasBeen3DaysSinceLastNotification &&
        _latestVersion!.shouldNotify!) {
      unawaited(
        NotificationService.instance.showNotification(
          "Update available",
          "Click to install our best version yet",
        ),
      );
      await _prefs.setInt(kUpdateAvailableShownTimeKey, now);
    } else {
      _logger.info("Debouncing notification");
    }
  }

  Future<LatestVersionInfo> _getLatestVersionInfo() async {
    final response = await Network.instance
        .getDio()
        .get("https://ente.io/release-info/auth-independent.json");
    return LatestVersionInfo.fromMap(response.data["latestVersion"]);
  }

  // getRateDetails returns details about the place
  Tuple2<String, String> getRateDetails() {
    // Note: in auth, currently we don't have a way to identify if the
    // app was installed from play store, f-droid or github based on pkg name
    if (Platform.isAndroid) {
      if (flavor == "playstore") {
        return const Tuple2(
          "Play Store",
          "market://details?id=io.ente.auth",
        );
      }
      return const Tuple2(
        "AlternativeTo",
        "https://alternativeto.net/software/ente-authenticator/about/",
      );
    }
    return const Tuple2(
      "App Store",
      "https://apps.apple.com/in/app/ente-photos/id6444121398",
    );
  }

  Future<void> launchReviewUrl() async {
    final String url = getRateDetails().item2;
    try {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      _logger.severe("Failed top open launch url $url", e);
      // Fall back if we fail to open play-store market app on android
      if (Platform.isAndroid && url.startsWith("market://")) {
        launchUrlString(
          "https://play.google.com/store/apps/details?id=io.ente.auth",
          mode: LaunchMode.externalApplication,
        ).ignore();
      }
    }
  }

  bool isIndependent() {
    return flavor == "independent" ||
        _packageInfo.packageName.endsWith("independent") ||
        PlatformUtil.isDesktop();
  }
}

class LatestVersionInfo {
  final String? name;
  final int? code;
  final List<String> changelog;
  final bool? shouldForceUpdate;
  final int lastSupportedVersionCode;
  final String? url;
  final String? release;
  final int? size;
  final bool? shouldNotify;

  LatestVersionInfo(
    this.name,
    this.code,
    this.changelog,
    this.shouldForceUpdate,
    this.lastSupportedVersionCode,
    this.url,
    this.release,
    this.size,
    this.shouldNotify,
  );

  factory LatestVersionInfo.fromMap(Map<String, dynamic> map) {
    return LatestVersionInfo(
      map['name'],
      map['code'],
      List<String>.from(map['changelog']),
      map['shouldForceUpdate'],
      map['lastSupportedVersionCode'] ?? 1,
      map['url'],
      map['release'],
      map['size'],
      map['shouldNotify'],
    );
  }
}
