import "dart:io";

import "package:android_intent_plus/android_intent.dart";
import "package:flutter/widgets.dart";
import "package:logging/logging.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:photos/services/remote_sync_service.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class DeeplinkService {
  static final DeeplinkService instance = DeeplinkService._privateConstructor();
  DeeplinkService._privateConstructor();

  static const hasConfiguredDeeplinkPermissionKey =
      "has_configured_deeplink_permission";
  late SharedPreferences _preferences;
  final _logger = Logger("NotificationService");

  void init(SharedPreferences preferences) {
    _preferences = preferences;
  }

  Future<void> requestDeeplinkPermissions(BuildContext context) async {
    _logger.info("Requesting to allow opening public links in-app");
    try {
      if (!hasConfiguredDeeplinkPermissions() &&
          RemoteSyncService.instance.isFirstRemoteSyncDone()) {
        final choice = await showChoiceActionSheet(
          isDismissible: false,
          context,
          title: "",
          body: "Allow app to open album links",
          firstButtonLabel: "Allow",
        );
        if (choice!.action == ButtonAction.first) {
          if (Platform.isAndroid) {
            final AndroidIntent intent;
            final PackageInfo packageInfo = await PackageInfo.fromPlatform();
            if (packageInfo.packageName == 'io.ente.photos.independent') {
              intent = const AndroidIntent(
                action: 'android.settings.APP_OPEN_BY_DEFAULT_SETTINGS',
                package: 'io.ente.photos.independent',
                data: 'package:io.ente.photos.independent',
              );
              await intent.launch();
            } else if (packageInfo.packageName == 'io.ente.photos.fdroid') {
              intent = const AndroidIntent(
                action: 'android.settings.APP_OPEN_BY_DEFAULT_SETTINGS',
                package: 'io.ente.photos.fdroid',
                data: 'package:io.ente.photos.fdroid',
              );
              await intent.launch();
            }
            await setConfiguredDeeplinkPermissions(true);
            _logger.info("Deeplink permissions granted");
          }
        } else {
          _logger.info("Deeplink permissions not granted");
        }
      }
    } catch (e) {
      _logger.severe("Failed to req deeplink permission for album links", e);
    }
  }

  Future<void> setConfiguredDeeplinkPermissions(bool value) async {
    await _preferences.setBool(hasConfiguredDeeplinkPermissionKey, value);
  }

  bool hasConfiguredDeeplinkPermissions() {
    final result = _preferences.getBool(hasConfiguredDeeplinkPermissionKey);
    return result ?? false;
  }
}
