import "dart:async";
import "dart:typed_data";

import "package:ente_crypto/ente_crypto.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/two_factor_status_change_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/user_details.dart";
import "package:photos/services/account/passkey_service.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/services/local_authentication_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/account/request_pwd_verification_page.dart";
import "package:photos/ui/account/sessions_page.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/settings/lock_screen/lock_screen_options.dart";
import "package:photos/utils/auth_util.dart";
import "package:photos/utils/dialog_util.dart";

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _config = Configuration.instance;
  late StreamSubscription<TwoFactorStatusChangeEvent>
      _twoFactorStatusChangeEvent;
  final Logger _logger = Logger("SecuritySettingsPage");

  @override
  void initState() {
    super.initState();
    _twoFactorStatusChangeEvent =
        Bus.instance.on<TwoFactorStatusChangeEvent>().listen((event) async {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _twoFactorStatusChangeEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.strokeBase,
                  size: 24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).security,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_config.hasConfiguredAccount()) ...[
                        MenuItemWidgetNew(
                          title: AppLocalizations.of(context).twofactor,
                          leadingIconWidget: _buildIconWidget(
                            context,
                            HugeIcons.strokeRoundedSmartPhone01,
                          ),
                          trailingWidget: ToggleSwitchWidget(
                            value: () =>
                                UserService.instance.hasEnabledTwoFactor(),
                            onChanged: () => _onTwoFactorToggle(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        MenuItemWidgetNew(
                          title: AppLocalizations.of(context)
                              .emailVerificationToggle,
                          leadingIconWidget: _buildIconWidget(
                            context,
                            HugeIcons.strokeRoundedMailSecure01,
                          ),
                          trailingWidget: ToggleSwitchWidget(
                            value: () =>
                                UserService.instance.hasEmailMFAEnabled(),
                            onChanged: () => _onEmailMFAToggle(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        MenuItemWidgetNew(
                          title: context.l10n.passkey,
                          leadingIconWidget: _buildIconWidget(
                            context,
                            HugeIcons.strokeRoundedFingerAccess,
                          ),
                          trailingIcon: Icons.chevron_right_outlined,
                          trailingIconIsMuted: true,
                          onTap: () async => _onPasskeyTap(context),
                        ),
                        const SizedBox(height: 8),
                      ],
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).appLock,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedSquareLock02,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async => _onAppLockTap(context),
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).activeSessions,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedComputerPhoneSync,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        showOnlyLoadingState: true,
                        onTap: () async => _onActiveSessionsTap(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconWidget(BuildContext context, List<List<dynamic>> icon) {
    final colorScheme = getEnteColorScheme(context);
    return HugeIcon(
      icon: icon,
      color: colorScheme.strokeBase,
      size: 20,
    );
  }

  Future<void> _onTwoFactorToggle(BuildContext context) async {
    final completer = Completer();
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      AppLocalizations.of(context).authToConfigureTwofactorAuthentication,
    );
    final isTwoFactorEnabled = UserService.instance.hasEnabledTwoFactor();
    if (hasAuthenticated) {
      if (isTwoFactorEnabled) {
        await _disableTwoFactor();
        completer.isCompleted ? null : completer.complete();
      } else {
        await UserService.instance.setupTwoFactor(context, completer);
      }
      return completer.future;
    }
  }

  Future<void> _disableTwoFactor() async {
    final alert = AlertDialog(
      title: Text(AppLocalizations.of(context).disableTwofactor),
      content: Text(
        AppLocalizations.of(context).confirm2FADisable,
      ),
      actions: [
        TextButton(
          child: Text(
            AppLocalizations.of(context).no,
            style: TextStyle(
              color: getEnteColorScheme(context).primary500,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop("dialog");
          },
        ),
        TextButton(
          child: Text(
            AppLocalizations.of(context).yes,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () async {
            await UserService.instance.disableTwoFactor(context);
            Navigator.of(context).pop("dialog");
          },
        ),
      ],
    );

    await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> _onEmailMFAToggle(BuildContext context) async {
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      AppLocalizations.of(context).authToChangeEmailVerificationSetting,
    );
    final isEmailMFAEnabled = UserService.instance.hasEmailMFAEnabled();
    if (hasAuthenticated) {
      await _updateEmailMFA(!isEmailMFAEnabled);
    }
  }

  Future<void> _updateEmailMFA(bool isEnabled) async {
    try {
      final UserDetails details =
          await UserService.instance.getUserDetailsV2(memoryCount: false);
      if ((details.profileData?.canDisableEmailMFA ?? false) == false) {
        await routeToPage(
          context,
          RequestPasswordVerificationPage(
            onPasswordVerified: (Uint8List keyEncryptionKey) async {
              final Uint8List loginKey =
                  await CryptoUtil.deriveLoginKey(keyEncryptionKey);
              await UserService.instance.registerOrUpdateSrp(loginKey);
            },
          ),
        );
      }
      await UserService.instance.updateEmailMFA(isEnabled);
    } catch (e) {
      showToast(context, AppLocalizations.of(context).somethingWentWrong);
    }
  }

  Future<void> _onPasskeyTap(BuildContext context) async {
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      AppLocalizations.of(context).authToViewPasskey,
    );
    if (hasAuthenticated) {
      await _handlePasskeyClick(context);
    }
  }

  Future<void> _handlePasskeyClick(BuildContext buildContext) async {
    try {
      final isPassKeyResetEnabled =
          await PasskeyService.instance.isPasskeyRecoveryEnabled();
      if (!isPassKeyResetEnabled) {
        final Uint8List recoveryKey =
            await UserService.instance.getOrCreateRecoveryKey(context);
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
      PasskeyService.instance.openPasskeyPage(buildContext).ignore();
    } catch (e, s) {
      _logger.severe("failed to open passkey page", e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _onAppLockTap(BuildContext context) async {
    if (await LocalAuthentication().isDeviceSupported()) {
      final bool result = await requestAuthentication(
        context,
        AppLocalizations.of(context).authToChangeLockscreenSetting,
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
        AppLocalizations.of(context).noSystemLockFound,
        AppLocalizations.of(context)
            .toEnableAppLockPleaseSetupDevicePasscodeOrScreen,
      );
    }
  }

  Future<void> _onActiveSessionsTap(BuildContext context) async {
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      AppLocalizations.of(context).authToViewYourActiveSessions,
    );
    if (hasAuthenticated) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const SessionsPage();
            },
          ),
        ),
      );
    }
  }
}
