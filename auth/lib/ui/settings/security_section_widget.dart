import 'dart:async';
import 'dart:typed_data';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/user_details.dart';
import 'package:ente_auth/services/auth_feature_flag.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/services/passkey_service.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/account/request_pwd_verification_page.dart';
import 'package:ente_auth/ui/account/sessions_page.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/components/toggle_switch_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/utils/crypto_util.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/navigation_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';

class SecuritySectionWidget extends StatefulWidget {
  const SecuritySectionWidget({Key? key}) : super(key: key);

  @override
  State<SecuritySectionWidget> createState() => _SecuritySectionWidgetState();
}

class _SecuritySectionWidgetState extends State<SecuritySectionWidget> {
  final _config = Configuration.instance;
  late bool _hasLoggedIn;

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
      final bool? canDisableMFA = UserService.instance.canDisableEmailMFA();
      if (canDisableMFA == null) {
        // We don't know if the user can disable MFA yet, so we fetch the info
        UserService.instance.getUserDetailsV2().ignore();
      }
      final bool isInternalUser =
          FeatureFlagService.instance.isInternalUserOrDebugBuild();
      children.addAll([
        if (isInternalUser) sectionOptionSpacing,
        if (isInternalUser)
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: l10n.passkey,
            ),
            pressedColor: getEnteColorScheme(context).fillFaint,
            trailingIcon: Icons.chevron_right_outlined,
            trailingIconIsMuted: true,
            onTap: () => PasskeyService.instance.openPasskeyPage(context),
          ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: l10n.emailVerificationToggle,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => UserService.instance.hasEmailMFAEnabled(),
            onChanged: () async {
              final hasAuthenticated = await LocalAuthenticationService.instance
                  .requestLocalAuthentication(
                context,
                l10n.authToChangeEmailVerificationSetting,
              );
              final isEmailMFAEnabled =
                  UserService.instance.hasEmailMFAEnabled();
              if (hasAuthenticated) {
                await updateEmailMFA(!isEmailMFAEnabled);
                if (mounted) {
                  setState(() {});
                }
              }
            },
          ),
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: context.l10n.viewActiveSessions,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            final hasAuthenticated = await LocalAuthenticationService.instance
                .requestLocalAuthentication(
              context,
              context.l10n.authToViewYourActiveSessions,
            );
            if (hasAuthenticated) {
              // ignore: unawaited_futures
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const SessionsPage();
                  },
                ),
              );
            }
          },
        ),
      ]);
    } else {
      children.add(sectionOptionSpacing);
    }
    children.addAll([
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: l10n.lockscreen,
        ),
        trailingWidget: ToggleSwitchWidget(
          value: () => _config.shouldShowLockScreen(),
          onChanged: () async {
            final hasAuthenticated = await LocalAuthenticationService.instance
                .requestLocalAuthForLockScreen(
              context,
              !_config.shouldShowLockScreen(),
              context.l10n.authToChangeLockscreenSetting,
              context.l10n.lockScreenEnablePreSteps,
            );
            if (hasAuthenticated) {
              setState(() {});
            }
          },
        ),
      ),
      sectionOptionSpacing,
    ]);
    return Column(
      children: children,
    );
  }

  Future<void> updateEmailMFA(bool enableEmailMFA) async {
    try {
      final UserDetails details =
          await UserService.instance.getUserDetailsV2(memoryCount: false);
      if (details.profileData?.canDisableEmailMFA == false) {
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
      if (enableEmailMFA) {
        await showChoiceActionSheet(
          context,
          title: context.l10n.warning,
          body: context.l10n.emailVerificationEnableWarning,
          isCritical: true,
          firstButtonOnTap: () async {
            await UserService.instance.updateEmailMFA(enableEmailMFA);
          },
          secondButtonLabel: context.l10n.cancel,
          firstButtonLabel: context.l10n.iUnderStand,
        );
      } else {
        await UserService.instance.updateEmailMFA(enableEmailMFA);
      }
    } catch (e) {
      showToast(context, context.l10n.somethingWentWrongMessage);
    }
  }
}
