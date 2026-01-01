import "package:ente_accounts/pages/delete_account_page.dart";
import "package:ente_accounts/services/user_service.dart";
import "package:ente_crypto_dart/ente_crypto_dart.dart";
import "package:ente_lock_screen/local_authentication_service.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_utils/navigation_util.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/change_email_dialog_locker.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:locker/ui/components/recovery_key_sheet.dart";

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
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const ChangeEmailDialogLocker();
                },
                barrierColor: Colors.black.withValues(alpha: 0.85),
                barrierDismissible: false,
              );
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
