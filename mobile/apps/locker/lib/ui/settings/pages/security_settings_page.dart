import "package:ente_lock_screen/auth_util.dart";
import "package:ente_lock_screen/lock_screen_settings.dart";
import "package:ente_lock_screen/ui/lock_screen_options.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/settings/widgets/settings_widget.dart";

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = getEnteColorScheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitleBarTitleWidget(title: l10n.security),
              const SizedBox(height: 24),
              SettingsItem(
                title: l10n.appLock,
                onTap: () => _onAppLockTapped(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAppLockTapped(BuildContext context) async {
    final l10n = context.l10n;
    if (await LockScreenSettings.instance.isDeviceSupported()) {
      final bool result = await requestAuthentication(
        context,
        l10n.authToChangeLockscreenSetting,
      );
      if (result) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const LockScreenOptions();
            },
          ),
        );
      }
    } else {
      await showErrorDialog(
        context,
        l10n.noSystemLockFound,
        l10n.toEnableAppLockPleaseSetupDevicePasscodeOrScreen,
      );
    }
  }
}
