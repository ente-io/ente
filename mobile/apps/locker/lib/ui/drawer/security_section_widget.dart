import "dart:async";
import "dart:typed_data";

import "package:ente_accounts/models/user_details.dart";
import "package:ente_accounts/pages/request_pwd_verification_page.dart";
import "package:ente_accounts/services/passkey_service.dart";
import "package:ente_accounts/services/user_service.dart";
import "package:ente_crypto_api/ente_crypto_api.dart";
import "package:ente_lock_screen/auth_util.dart";
import "package:ente_lock_screen/local_authentication_service.dart";
import "package:ente_lock_screen/lock_screen_settings.dart";
import "package:ente_lock_screen/ui/lock_screen_options.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:logging/logging.dart";


class SecuritySectionWidget extends StatefulWidget {
  const SecuritySectionWidget({super.key});

  @override
  State<SecuritySectionWidget> createState() => _SecuritySectionWidgetState();
}

class _SecuritySectionWidgetState extends State<SecuritySectionWidget> {
  final Logger _logger = Logger("SecuritySectionWidget");

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.security,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: HugeIcons.strokeRoundedSecurityCheck,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        // TODO: Enable when ready
        // ExpandableChildItem(
        //   title: l10n.emailVerificationToggle,
        //   trailingWidget: ToggleSwitchWidget(
        //     value: () => UserService.instance.hasEmailMFAEnabled(),
        //     onChanged: () async {
        //       final hasAuthenticated = await LocalAuthenticationService
        //           .instance
        //           .requestLocalAuthentication(
        //         context,
        //         l10n.authToChangeEmailVerificationSetting,
        //       );
        //       final isEmailMFAEnabled =
        //           UserService.instance.hasEmailMFAEnabled();
        //       if (hasAuthenticated) {
        //         await updateEmailMFA(!isEmailMFAEnabled);
        //       }
        //     },
        //   ),
        // ),
        // TODO: Enable when ready
        // ExpandableChildItem(
        //   title: l10n.passkey,
        //   trailingIcon: Icons.chevron_right,
        //   onTap: () async {
        //     final hasAuthenticated = await LocalAuthenticationService.instance
        //         .requestLocalAuthentication(
        //       context,
        //       l10n.authToViewPasskey,
        //     );
        //     if (hasAuthenticated) {
        //       await onPasskeyClick(context);
        //     }
        //   },
        // ),
        ExpandableChildItem(
          title: l10n.appLock,
          trailingIcon: Icons.chevron_right,
          onTap: () async {
            if (await LockScreenSettings.instance.isDeviceSupported()) {
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
              await showErrorDialog(
                context,
                context.l10n.noSystemLockFound,
                context.l10n.toEnableAppLockPleaseSetupDevicePasscodeOrScreen,
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> onPasskeyClick(BuildContext buildContext) async {
    try {
      final hasAuthenticated =
          await LocalAuthenticationService.instance.requestLocalAuthentication(
        context,
        context.l10n.authenticateGeneric,
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
