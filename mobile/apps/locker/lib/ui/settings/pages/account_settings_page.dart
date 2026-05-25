import "package:ente_accounts/pages/change_email_dialog.dart";
import "package:ente_accounts/pages/password_entry_page.dart";
import "package:ente_components/ente_components.dart";
import "package:ente_crypto_api/ente_crypto_api.dart";
import "package:ente_lock_screen/local_authentication_service.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:ente_strings/extensions.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_utils/email_util.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/recovery_key_sheet.dart";
import "package:locker/ui/pages/delete_account_page.dart";
import "package:locker/ui/pages/home_page.dart";
import "package:locker/ui/settings/components/settings_item.dart";
import "package:locker/ui/settings/components/settings_page_scaffold.dart";

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsPageScaffold(
      title: l10n.account,
      children: [
        SettingsItem(
          title: l10n.changeEmail,
          icon: HugeIcons.strokeRoundedMail01,
          showOnlyLoadingState: true,
          onTap: () => _onChangeEmailTapped(context),
        ),
        const SizedBox(height: 8),
        SettingsItem(
          title: l10n.recoveryKey,
          icon: HugeIcons.strokeRoundedKey01,
          showOnlyLoadingState: true,
          onTap: () => _onRecoveryKeyTapped(context),
        ),
        const SizedBox(height: 8),
        SettingsItem(
          title: l10n.changePassword,
          icon: HugeIcons.strokeRoundedLockPassword,
          showOnlyLoadingState: true,
          onTap: () => _onChangePasswordTapped(context),
        ),
        const SizedBox(height: 8),
        SettingsItem(
          title: l10n.deleteAccount,
          icon: HugeIcons.strokeRoundedDelete02,
          isDestructive: true,
          onTap: () => _onDeleteAccountTapped(context),
        ),
      ],
    );
  }

  Future<void> _onChangeEmailTapped(BuildContext context) async {
    final l10n = context.l10n;
    final hasAuthenticated = await LocalAuthenticationService.instance
        .requestLocalAuthentication(context, l10n.authToChangeYourEmail);
    if (hasAuthenticated) {
      // ignore: unawaited_futures
      showChangeEmailDialog(context);
    }
  }

  Future<void> _onRecoveryKeyTapped(BuildContext context) async {
    final l10n = context.l10n;
    final hasAuthenticated = await LocalAuthenticationService.instance
        .requestLocalAuthentication(context, l10n.authToViewYourRecoveryKey);
    if (hasAuthenticated) {
      String recoveryKey;
      try {
        recoveryKey = CryptoUtil.bin2hex(
          Configuration.instance.getRecoveryKey(),
        );
      } catch (e) {
        await showErrorBottomSheetComponent<void>(
          context: context,
          message: parseErrorForUI(
            context,
            context.strings.itLooksLikeSomethingWentWrongPleaseRetryAfterSome,
            error: e,
            surfaceError: false,
          ),
          title: context.strings.error,
          actionLabel: context.strings.contactSupport,
          onActionTap: () async {
            await sendLogs(context, "support@ente.com", postShare: () {});
          },
        );
        return;
      }
      await showRecoveryKeySheet(context, recoveryKey: recoveryKey);
    }
  }

  Future<void> _onChangePasswordTapped(BuildContext context) async {
    final l10n = context.l10n;
    final hasAuthenticated = await LocalAuthenticationService.instance
        .requestLocalAuthentication(context, l10n.authToChangeYourPassword);
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
  }

  void _onDeleteAccountTapped(BuildContext context) {
    final config = Configuration.instance;
    // ignore: unawaited_futures
    routeToPage(context, DeleteAccountPage(config));
  }
}
