import "dart:typed_data";

import "package:ente_accounts/models/user_details.dart";
import "package:ente_accounts/pages/request_pwd_verification_page.dart";
import "package:ente_accounts/pages/sessions_page.dart";
import "package:ente_accounts/services/passkey_service.dart";
import "package:ente_accounts/services/user_service.dart";
import "package:ente_crypto_api/ente_crypto_api.dart";
import "package:ente_lock_screen/local_authentication_service.dart";
import "package:ente_lock_screen/lock_screen_settings.dart";
import "package:ente_lock_screen/ui/lock_screen_options.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/components/toggle_switch_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/settings/widgets/settings_widget.dart";
import "package:logging/logging.dart";

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _config = Configuration.instance;
  final Logger _logger = Logger('SecuritySettingsPage');
  late bool _hasLoggedIn;

  @override
  void initState() {
    _hasLoggedIn = _config.hasConfiguredAccount();
    super.initState();
  }

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
              if (_hasLoggedIn) ...[
                _buildEmailVerificationItem(context),
                const SizedBox(height: 12),
                _buildPasskeyItem(context),
                const SizedBox(height: 12),
              ],
              _buildAppLockItem(context),
              if (_hasLoggedIn) ...[
                const SizedBox(height: 12),
                _buildActiveSessionsItem(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailVerificationItem(BuildContext context) {
    final l10n = context.l10n;

    return SettingsItem(
      title: l10n.emailVerificationToggle,
      showChevron: false,
      trailing: ToggleSwitchWidget(
        value: () => UserService.instance.hasEmailMFAEnabled(),
        onChanged: () => _onEmailMFAToggle(context),
      ),
    );
  }

  Future<void> _onEmailMFAToggle(BuildContext context) async {
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      context.l10n.authToChangeEmailVerificationSetting,
    );
    final isEmailMFAEnabled = UserService.instance.hasEmailMFAEnabled();
    if (hasAuthenticated) {
      await _updateEmailMFA(!isEmailMFAEnabled);
    }
  }

  Widget _buildPasskeyItem(BuildContext context) {
    final l10n = context.l10n;
    return SettingsItem(
      title: l10n.passkey,
      onTap: () => _onPasskeyClick(context),
    );
  }

  Widget _buildActiveSessionsItem(BuildContext context) {
    final l10n = context.l10n;
    return SettingsItem(
      title: l10n.viewActiveSessions,
      onTap: () async {
        final hasAuthenticated = await LocalAuthenticationService.instance
            .requestLocalAuthentication(
          context,
          l10n.authToViewYourActiveSessions,
        );
        if (hasAuthenticated) {
          // ignore: unawaited_futures
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return SessionsPage(Configuration.instance);
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildAppLockItem(BuildContext context) {
    final l10n = context.l10n;
    return SettingsItem(
      title: l10n.appLock,
      onTap: () => _onAppLockTapped(context),
    );
  }

  Future<void> _onAppLockTapped(BuildContext context) async {
    final l10n = context.l10n;
    if (await LockScreenSettings.instance.isDeviceSupported()) {
      final hasAuthenticated =
          await LocalAuthenticationService.instance.requestLocalAuthentication(
        context,
        l10n.authToChangeLockscreenSetting,
      );
      if (hasAuthenticated) {
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

  Future<void> _onPasskeyClick(BuildContext buildContext) async {
    try {
      final hasAuthenticated =
          await LocalAuthenticationService.instance.requestLocalAuthentication(
        context,
        context.l10n.authToViewPasskey,
        refocusWindows: false,
      );
      if (!hasAuthenticated) {
        return;
      }
      final isPassKeyResetEnabled =
          await PasskeyService.instance.isPasskeyRecoveryEnabled();
      if (!isPassKeyResetEnabled) {
        final Uint8List recoveryKey = Configuration.instance.getRecoveryKey();
        final resetKey = CryptoUtil.generateKey();
        final resetKeyBase64 = CryptoUtil.bin2base64(resetKey);
        final encryptionResult = CryptoUtil.encryptSync(
          resetKey,
          recoveryKey,
        );
        await PasskeyService.instance.configurePasskeyRecovery(
          resetKeyBase64,
          CryptoUtil.bin2base64(encryptionResult.encryptedData!),
          CryptoUtil.bin2base64(encryptionResult.nonce!),
        );
      }
      await PasskeyService.instance.openPasskeyPage(buildContext);
    } catch (e, s) {
      _logger.severe("failed to open passkey page", e, s);
      await showGenericErrorDialog(
        context: context,
        error: e,
      );
    }
  }

  Future<void> _updateEmailMFA(bool isEnabled) async {
    try {
      final UserDetails details =
          await UserService.instance.getUserDetailsV2(memoryCount: false);
      if ((details.profileData?.canDisableEmailMFA ?? false) == false) {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return RequestPasswordVerificationPage(
                Configuration.instance,
                onPasswordVerified: (Uint8List keyEncryptionKey) async {
                  final Uint8List loginKey =
                      await CryptoUtil.deriveLoginKey(keyEncryptionKey);
                  await UserService.instance.registerOrUpdateSrp(loginKey);
                },
              );
            },
          ),
        );
        if (result != true) {
          return;
        }
      }
      await UserService.instance.updateEmailMFA(isEnabled);
    } catch (e) {
      showToast(context, context.l10n.somethingWentWrong);
    }
  }
}
