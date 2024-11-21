import "package:android_intent_plus/android_intent.dart";
import "package:flutter/widgets.dart";
import "package:logging/logging.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class DeeplinkService {
  static final DeeplinkService instance = DeeplinkService._privateConstructor();
  DeeplinkService._privateConstructor();

  static const _hasConfiguredDeeplinkPermissionKey =
      "has_configured_deeplink_permission";
  late SharedPreferences _preferences;
  final _logger = Logger("NotificationService");

  void init(SharedPreferences preferences) {
    _preferences = preferences;
  }

  Future<void> requestDeeplinkPermissions(
    BuildContext context,
    String packageName,
  ) async {
    _logger.info("Requesting to allow opening public links in-app");
    try {
      final choice = await showChoiceActionSheet(
        isDismissible: false,
        context,
        title: "See public album links in app",
        body: "Allow app to open shared album links",
        firstButtonLabel: "Allow",
      );
      if (choice!.action == ButtonAction.first) {
        final AndroidIntent intent;
        if (packageName == 'io.ente.photos.independent') {
          intent = const AndroidIntent(
            action: 'android.settings.APP_OPEN_BY_DEFAULT_SETTINGS',
            package: 'io.ente.photos.independent',
            data: 'package:io.ente.photos.independent',
          );
          await intent.launch();
        } else if (packageName == 'io.ente.photos.fdroid') {
          intent = const AndroidIntent(
            action: 'android.settings.APP_OPEN_BY_DEFAULT_SETTINGS',
            package: 'io.ente.photos.fdroid',
            data: 'package:io.ente.photos.fdroid',
          );
          await intent.launch();
        }
        await setConfiguredDeeplinkPermissions(true);
        _logger.info("Deeplink permissions granted");
      } else {
        _logger.info("Deeplink permissions not granted");
      }
    } catch (e) {
      _logger.severe("Failed to req deeplink permission for album links", e);
    }
  }

  Future<void> setConfiguredDeeplinkPermissions(bool value) async {
    await _preferences.setBool(_hasConfiguredDeeplinkPermissionKey, value);
  }

  /// This is only relevant for fdorid and independent builds since in them,
  /// user has to manually allow the app to open public links in-app
  bool hasConfiguredDeeplinkPermissions() {
    final result = _preferences.getBool(_hasConfiguredDeeplinkPermissionKey);
    return result ?? false;
  }
}
