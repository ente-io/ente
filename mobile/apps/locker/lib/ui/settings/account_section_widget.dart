import "package:ente_accounts/pages/change_email_dialog.dart";
import "package:ente_accounts/pages/delete_account_page.dart";
import "package:ente_accounts/pages/password_entry_page.dart";
import "package:ente_accounts/pages/recovery_key_page.dart";
import "package:ente_accounts/services/user_service.dart";
import "package:ente_crypto_dart/ente_crypto_dart.dart";
import "package:ente_lock_screen/local_authentication_service.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_utils/navigation_util.dart";
import "package:ente_utils/platform_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:locker/ui/pages/home_page.dart";
import "package:locker/ui/settings/common_settings.dart";

class AccountSectionWidget extends StatelessWidget {
  const AccountSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.account,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.account_circle_outlined,
    );
  }

  Column _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;
    final List<Widget> children = [];
    children.addAll([
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: l10n.changeEmail,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          final hasAuthenticated = await LocalAuthenticationService.instance
              .requestLocalAuthentication(
            context,
            l10n.authToChangeYourEmail,
          );
          await PlatformUtil.refocusWindows();
          if (hasAuthenticated) {
            // ignore: unawaited_futures
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const ChangeEmailDialog();
              },
              barrierColor: Colors.black.withValues(alpha: 0.85),
              barrierDismissible: false,
            );
          }
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: l10n.changePassword,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          final hasAuthenticated = await LocalAuthenticationService.instance
              .requestLocalAuthentication(
            context,
            l10n.authToChangeYourPassword,
          );
          if (hasAuthenticated) {
            // ignore: unawaited_futures
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return PasswordEntryPage(
                    Configuration.instance,
                    PasswordEntryMode.update,
                    const HomePage(),
                  );
                },
              ),
            );
          }
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: l10n.recoveryKey,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          final hasAuthenticated = await LocalAuthenticationService.instance
              .requestLocalAuthentication(
            context,
            l10n.authToViewYourRecoveryKey,
          );
          if (hasAuthenticated) {
            String recoveryKey;
            try {
              recoveryKey =
                  CryptoUtil.bin2hex(Configuration.instance.getRecoveryKey());
            } catch (e) {
              // ignore: unawaited_futures
              showGenericErrorDialog(
                context: context,
                error: e,
              );
              return;
            }
            // ignore: unawaited_futures
            routeToPage(
              context,
              RecoveryKeyPage(
                Configuration.instance,
                recoveryKey,
                l10n.ok,
                showAppBar: true,
                onDone: () {},
              ),
            );
          }
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: context.l10n.logout,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          _onLogoutTapped(context);
        },
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: context.l10n.deleteAccount,
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          final config = Configuration.instance;
          // ignore: unawaited_futures
          routeToPage(context, DeleteAccountPage(config));
        },
      ),
      sectionOptionSpacing,
    ]);
    return Column(
      children: children,
    );
  }

  void _onLogoutTapped(BuildContext context) {
    showChoiceActionSheet(
      context,
      title: context.l10n.areYouSureYouWantToLogout,
      firstButtonLabel: context.l10n.yesLogout,
      isCritical: true,
      firstButtonOnTap: () async {
        await UserService.instance.logout(context);
      },
    );
  }
}
