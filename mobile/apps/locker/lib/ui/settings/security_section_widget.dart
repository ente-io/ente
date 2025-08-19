import "dart:async";
import "dart:typed_data";

import "package:ente_accounts/models/user_details.dart";
import "package:ente_accounts/pages/request_pwd_verification_page.dart";
import "package:ente_accounts/services/passkey_service.dart";
import "package:ente_accounts/services/user_service.dart";
import "package:ente_crypto_dart/ente_crypto_dart.dart";
import "package:ente_lock_screen/auth_util.dart";
import "package:ente_lock_screen/local_authentication_service.dart";
import "package:ente_lock_screen/lock_screen_settings.dart";
import "package:ente_lock_screen/ui/lock_screen_options.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/components/toggle_switch_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/navigation_util.dart";
import "package:ente_utils/platform_util.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:locker/ui/settings/common_settings.dart";
import "package:logging/logging.dart";

class SecuritySectionWidget extends StatefulWidget {
  const SecuritySectionWidget({super.key});

  @override
  State<SecuritySectionWidget> createState() => _SecuritySectionWidgetState();
}

class _SecuritySectionWidgetState extends State<SecuritySectionWidget> {
  final _config = Configuration.instance;
  late bool _hasLoggedIn;
  final Logger _logger = Logger('SecuritySectionWidget');

  @override
  void initState() {
    _hasLoggedIn = _config.hasConfiguredAccount();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.security,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.local_police_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;
    final List<Widget> children = [];
    if (_hasLoggedIn) {
      children.addAll(
        [
          sectionOptionSpacing,
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: l10n.emailVerificationToggle,
            ),
            trailingWidget: ToggleSwitchWidget(
              value: () => UserService.instance.hasEmailMFAEnabled(),
              onChanged: () async {
                final hasAuthenticated = await LocalAuthenticationService
                    .instance
                    .requestLocalAuthentication(
                  context,
                  l10n.authToChangeEmailVerificationSetting,
                );
                final isEmailMFAEnabled =
                    UserService.instance.hasEmailMFAEnabled();
                if (hasAuthenticated) {
                  await updateEmailMFA(!isEmailMFAEnabled);
                }
              },
            ),
          ),
          sectionOptionSpacing,
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: context.l10n.passkey,
            ),
            pressedColor: getEnteColorScheme(context).fillFaint,
            trailingIcon: Icons.chevron_right_outlined,
            trailingIconIsMuted: true,
            onTap: () async {
              final hasAuthenticated = await LocalAuthenticationService.instance
                  .requestLocalAuthentication(
                context,
                l10n.authToViewPasskey,
              );
              if (hasAuthenticated) {
                await onPasskeyClick(context);
              }
            },
          ),
          sectionOptionSpacing,
        ],
      );
    } else {
      children.add(sectionOptionSpacing);
    }
    children.addAll([
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: context.l10n.appLock,
        ),
        surfaceExecutionStates: false,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          if (await LockScreenSettings.instance.shouldShowLockScreen()) {
            final bool result = await requestAuthentication(
              context,
              context.l10n.authToChangeLockscreenSetting,
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
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const LockScreenOptions();
                },
              ),
            );
          }
        },
      ),
      sectionOptionSpacing,
    ]);
    
    return Column(
      children: children,
    );
  }

  Future<void> onPasskeyClick(BuildContext buildContext) async {
    try {
      final hasAuthenticated =
          await LocalAuthenticationService.instance.requestLocalAuthentication(
        context,
        context.l10n.authenticateGeneric,
      );
      await PlatformUtil.refocusWindows();
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
      PasskeyService.instance.openPasskeyPage(buildContext).ignore();
    } catch (e, s) {
      _logger.severe("failed to open passkey page", e, s);
      await showGenericErrorDialog(
        context: context,
        error: e,
      );
    }
  }

  Future<void> updateEmailMFA(bool isEnabled) async {
    try {
      final UserDetails details =
          await UserService.instance.getUserDetailsV2(memoryCount: false);
      if ((details.profileData?.canDisableEmailMFA ?? false) == false) {
        await routeToPage(
          context,
          RequestPasswordVerificationPage(
            Configuration.instance,
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
      showToast(context, context.l10n.somethingWentWrong);
    }
  }
}
