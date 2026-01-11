import 'package:ente_crypto/ente_crypto.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/services/sync/local_sync_service.dart';
import 'package:photos/services/sync/sync_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/toggle_switch_widget.dart';
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/debug/social_debug_screen.dart';
import 'package:photos/utils/navigation_util.dart';

class DebugSectionWidget extends StatefulWidget {
  const DebugSectionWidget({super.key});

  @override
  State<DebugSectionWidget> createState() => _DebugSectionWidgetState();
}

class _DebugSectionWidgetState extends State<DebugSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "Debug",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.bug_report_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Disable internal user features",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingWidget: ToggleSwitchWidget(
            value: () => localSettings.isInternalUserDisabled,
            onChanged: () async {
              final newValue = !localSettings.isInternalUserDisabled;
              await localSettings.setInternalUserDisabled(newValue);
              setState(() {});
              showShortToast(
                context,
                newValue
                    ? "Internal user disabled. Restart app."
                    : "Internal user enabled. Restart app.",
              );
            },
          ),
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Enable database logging",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingWidget: ToggleSwitchWidget(
            value: () => localSettings.enableDatabaseLogging,
            onChanged: () async {
              final newValue = !localSettings.enableDatabaseLogging;
              await localSettings.setEnableDatabaseLogging(newValue);
              setState(() {});
              showShortToast(
                context,
                newValue
                    ? "Database logging enabled. Restart app."
                    : "Database logging disabled. Restart app.",
              );
            },
          ),
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Show local ID over thumbnails",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingWidget: ToggleSwitchWidget(
            value: () => localSettings.showLocalIDOverThumbnails,
            onChanged: () async {
              await localSettings.setShowLocalIDOverThumbnails(
                !localSettings.showLocalIDOverThumbnails,
              );
              setState(() {});
              showShortToast(
                context,
                localSettings.showLocalIDOverThumbnails
                    ? "Local IDs will be shown. Restart app."
                    : "Local IDs hidden. Restart app.",
              );
            },
          ),
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Key attributes",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await updateService.resetChangeLog();
            _showKeyAttributesDialog(context);
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Delete Local Import DB",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await LocalSyncService.instance.resetLocalSync();
            showShortToast(context, "Done");
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Allow auto-upload for ignored files",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await IgnoredFilesService.instance.reset();
            SyncService.instance.sync().ignore();
            showShortToast(context, "Done");
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Social settings",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await routeToPage(context, const SocialDebugScreen());
          },
        ),
      ],
    );
  }

  void _showKeyAttributesDialog(BuildContext context) {
    final keyAttributes = Configuration.instance.getKeyAttributes()!;
    final AlertDialog alert = AlertDialog(
      title: const Text("key attributes"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Key",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(CryptoUtil.bin2base64(Configuration.instance.getKey()!)),
            const Padding(padding: EdgeInsets.all(12)),
            const Text(
              "Encrypted Key",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(keyAttributes.encryptedKey),
            const Padding(padding: EdgeInsets.all(12)),
            const Text(
              "Key Decryption Nonce",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(keyAttributes.keyDecryptionNonce),
            const Padding(padding: EdgeInsets.all(12)),
            const Text(
              "KEK Salt",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(keyAttributes.kekSalt),
            const Padding(padding: EdgeInsets.all(12)),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("OK"),
          onPressed: () {
            Navigator.of(context).pop('dialog');
          },
        ),
      ],
    );

    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
