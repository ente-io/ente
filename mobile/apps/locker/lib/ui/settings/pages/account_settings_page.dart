import "package:ente_accounts/pages/change_email_dialog.dart";
import "package:ente_accounts/pages/delete_account_page.dart";
import "package:ente_accounts/pages/password_entry_page.dart";
import "package:ente_crypto_api/ente_crypto_api.dart";
import "package:ente_lock_screen/local_authentication_service.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/recovery_key_sheet.dart";
import "package:locker/ui/pages/home_page.dart";
import "package:locker/ui/settings/widgets/settings_widget.dart";

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

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
              TitleBarTitleWidget(title: l10n.account),
              const SizedBox(height: 24),
              SettingsItem(
                title: l10n.changeEmail,
                onTap: () => _onChangeEmailTapped(context),
              ),
              const SizedBox(height: 8),
              SettingsItem(
                title: l10n.recoveryKey,
                onTap: () => _onRecoveryKeyTapped(context),
              ),
              const SizedBox(height: 8),
              SettingsItem(
                title: l10n.changePassword,
                onTap: () => _onChangePasswordTapped(context),
              ),
              const SizedBox(height: 8),
              SettingsItem(
                title: l10n.deleteAccount,
                textColor: colorScheme.warning500,
                onTap: () => _onDeleteAccountTapped(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onChangeEmailTapped(BuildContext context) async {
    final l10n = context.l10n;
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      l10n.authToChangeYourEmail,
    );
    if (hasAuthenticated) {
      // ignore: unawaited_futures
      showChangeEmailDialog(context);
    }
  }

  Future<void> _onRecoveryKeyTapped(BuildContext context) async {
    final l10n = context.l10n;
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
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
  }

  Future<void> _onChangePasswordTapped(BuildContext context) async {
    final l10n = context.l10n;
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
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
  }

  void _onDeleteAccountTapped(BuildContext context) {
    final config = Configuration.instance;
    // ignore: unawaited_futures
    routeToPage(context, DeleteAccountPage(config));
  }
}
