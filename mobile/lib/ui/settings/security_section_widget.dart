import 'dart:async';
import "dart:typed_data";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/two_factor_status_change_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/user_details.dart";
import 'package:photos/services/local_authentication_service.dart';
import "package:photos/services/passkey_service.dart";
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/account/request_pwd_verification_page.dart";
import 'package:photos/ui/account/sessions_page.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/toggle_switch_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import "package:photos/utils/crypto_util.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/toast_util.dart";

class SecuritySectionWidget extends StatefulWidget {
  const SecuritySectionWidget({Key? key}) : super(key: key);

  @override
  State<SecuritySectionWidget> createState() => _SecuritySectionWidgetState();
}

class _SecuritySectionWidgetState extends State<SecuritySectionWidget> {
  final _config = Configuration.instance;

  late StreamSubscription<TwoFactorStatusChangeEvent>
      _twoFactorStatusChangeEvent;
  final Logger _logger = Logger('SecuritySectionWidget');
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
    return ExpandableMenuItemWidget(
      title: S.of(context).security,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.local_police_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final Completer completer = Completer();
    final List<Widget> children = [];
    if (_config.hasConfiguredAccount()) {
      children.addAll(
        [
          sectionOptionSpacing,
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: S.of(context).twofactor,
            ),
            trailingWidget: ToggleSwitchWidget(
              value: () => UserService.instance.hasEnabledTwoFactor(),
              onChanged: () async {
                final hasAuthenticated = await LocalAuthenticationService
                    .instance
                    .requestLocalAuthentication(
                  context,
                  S.of(context).authToConfigureTwofactorAuthentication,
                );
                final isTwoFactorEnabled =
                    UserService.instance.hasEnabledTwoFactor();
                if (hasAuthenticated) {
                  if (isTwoFactorEnabled) {
                    await _disableTwoFactor();
                    completer.isCompleted ? null : completer.complete();
                  } else {
                    await UserService.instance
                        .setupTwoFactor(context, completer);
                  }
                  return completer.future;
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
            onTap: () async => await onPasskeyClick(context),
          ),
          sectionOptionSpacing,
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: S.of(context).emailVerificationToggle,
            ),
            trailingWidget: ToggleSwitchWidget(
              value: () => UserService.instance.hasEmailMFAEnabled(),
              onChanged: () async {
                final hasAuthenticated = await LocalAuthenticationService
                    .instance
                    .requestLocalAuthentication(
                  context,
                  S.of(context).authToChangeEmailVerificationSetting,
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
        ],
      );
    }
    children.addAll([
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: S.of(context).lockscreen,
        ),
        trailingWidget: ToggleSwitchWidget(
          value: () => _config.shouldShowLockScreen(),
          onChanged: () async {
            await LocalAuthenticationService.instance
                .requestLocalAuthForLockScreen(
              context,
              !_config.shouldShowLockScreen(),
              S.of(context).authToChangeLockscreenSetting,
              S.of(context).lockScreenEnablePreSteps,
            );
          },
        ),
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: S.of(context).viewActiveSessions,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        showOnlyLoadingState: true,
        onTap: () async {
          final hasAuthenticated = await LocalAuthenticationService.instance
              .requestLocalAuthentication(
            context,
            S.of(context).authToViewYourActiveSessions,
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
        },
      ),
      sectionOptionSpacing,
    ]);
    return Column(
      children: children,
    );
  }

  Future<void> _disableTwoFactor() async {
    final AlertDialog alert = AlertDialog(
      title: Text(S.of(context).disableTwofactor),
      content: Text(
        S.of(context).confirm2FADisable,
      ),
      actions: [
        TextButton(
          child: Text(
            S.of(context).no,
            style: TextStyle(
              color: Theme.of(context).colorScheme.greenAlternative,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
        TextButton(
          child: Text(
            S.of(context).yes,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () async {
            await UserService.instance.disableTwoFactor(context);
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> onPasskeyClick(BuildContext buildContext) async {
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

  Future<void> updateEmailMFA(bool isEnabled) async {
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
      showToast(context, S.of(context).somethingWentWrong);
    }
  }
}
