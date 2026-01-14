import "package:ente_accounts/pages/change_email_dialog.dart";
import "package:ente_accounts/pages/delete_account_page.dart";
import "package:ente_accounts/pages/password_entry_page.dart";
import "package:ente_accounts/services/user_service.dart";
import "package:ente_crypto_api/ente_crypto_api.dart";
import "package:ente_lock_screen/local_authentication_service.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:ente_ui/components/alert_bottom_sheet.dart";
import "package:ente_ui/components/buttons/gradient_button.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:locker/ui/components/recovery_key_sheet.dart";
import "package:locker/ui/pages/home_page.dart";

class AccountSectionWidget extends StatelessWidget {
  const AccountSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.account,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: HugeIcons.strokeRoundedUser,
    );
  }

  Column _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = getEnteColorScheme(context);

    return Column(
      children: [
        ExpandableChildItem(
          title: l10n.changeEmail,
          trailingIcon: Icons.chevron_right,
          onTap: () async {
            final hasAuthenticated = await LocalAuthenticationService.instance
                .requestLocalAuthentication(
              context,
              l10n.authToChangeYourEmail,
            );
            if (hasAuthenticated) {
              // ignore: unawaited_futures
              showChangeEmailDialog(context);
            }
          },
        ),
        ExpandableChildItem(
          title: l10n.recoveryKey,
          trailingIcon: Icons.chevron_right,
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
              await showRecoveryKeySheet(
                context,
                recoveryKey: recoveryKey,
              );
            }
          },
        ),
        ExpandableChildItem(
          title: l10n.changePassword,
          trailingIcon: Icons.chevron_right,
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
        ExpandableChildItem(
          title: l10n.deleteAccount,
          textColor: colorScheme.warning500,
          trailingIcon: Icons.chevron_right,
          trailingIconColor: colorScheme.warning500,
          onTap: () async {
            final config = Configuration.instance;
            // ignore: unawaited_futures
            routeToPage(context, DeleteAccountPage(config));
          },
        ),
        ExpandableChildItem(
          title: l10n.logout,
          trailingIcon: Icons.chevron_right,
          onTap: () async {
            _onLogoutTapped(context);
          },
        ),
      ],
    );
  }

  void _onLogoutTapped(BuildContext context) {
    showAlertBottomSheet(
      context,
      title: context.l10n.warning,
      message: context.l10n.areYouSureYouWantToLogout,
      assetPath: "assets/warning-grey.png",
      buttons: [
        GradientButton(
          buttonType: GradientButtonType.critical,
          text: context.l10n.yesLogout,
          onTap: () async {
            await UserService.instance.logout(context);
          },
        ),
      ],
    );
  }
}
