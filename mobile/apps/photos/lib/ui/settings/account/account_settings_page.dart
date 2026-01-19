import "dart:async";

import "package:ente_crypto/ente_crypto.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/services/local_authentication_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/account/change_email_dialog.dart";
import "package:photos/ui/account/delete_account_page.dart";
import "package:photos/ui/account/password_entry_page.dart";
import "package:photos/ui/account/recovery_key_page.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/payment/subscription.dart";
import "package:photos/utils/dialog_util.dart";
import "package:url_launcher/url_launcher_string.dart";

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

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
                AppLocalizations.of(context).account,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).manageSubscription,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedCreditCard,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async => _onManageSubscriptionTapped(context),
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).changeEmail,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedMail01,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        showOnlyLoadingState: true,
                        onTap: () async => _onChangeEmailTapped(context),
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).changePassword,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedLockPassword,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        showOnlyLoadingState: true,
                        onTap: () async => _onChangePasswordTapped(context),
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).recoveryKey,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedKey01,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        showOnlyLoadingState: true,
                        onTap: () async => _onRecoveryKeyTapped(context),
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).exportYourData,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedDownload04,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await launchUrlString(
                            "https://ente.io/help/photos/migration/export/",
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).deleteAccount,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedDelete02,
                          isDestructive: true,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async => _onDeleteAccountTapped(context),
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

  Widget _buildIconWidget(
    BuildContext context,
    List<List<dynamic>> icon, {
    bool isDestructive = false,
  }) {
    final colorScheme = getEnteColorScheme(context);
    return HugeIcon(
      icon: icon,
      color: isDestructive ? colorScheme.warning700 : colorScheme.strokeBase,
      size: 20,
    );
  }

  void _onManageSubscriptionTapped(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return getSubscriptionPage();
        },
      ),
    );
  }

  Future<void> _onChangeEmailTapped(BuildContext context) async {
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      AppLocalizations.of(context).authToChangeYourEmail,
    );
    if (hasAuthenticated) {
      unawaited(
        showDialog(
          useRootNavigator: false,
          context: context,
          builder: (BuildContext context) {
            return const ChangeEmailDialog();
          },
          barrierColor: Colors.black.withValues(alpha: 0.85),
          barrierDismissible: false,
        ),
      );
    }
  }

  Future<void> _onChangePasswordTapped(BuildContext context) async {
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      AppLocalizations.of(context).authToChangeYourPassword,
    );
    if (hasAuthenticated) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const PasswordEntryPage(
                mode: PasswordEntryMode.update,
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _onRecoveryKeyTapped(BuildContext context) async {
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      AppLocalizations.of(context).authToViewYourRecoveryKey,
    );
    if (hasAuthenticated) {
      String recoveryKey;
      try {
        recoveryKey = await _getOrCreateRecoveryKey(context);
      } catch (e) {
        await showGenericErrorDialog(context: context, error: e);
        return;
      }
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return RecoveryKeyPage(
                recoveryKey,
                AppLocalizations.of(context).ok,
                showAppBar: true,
                onDone: () {},
              );
            },
          ),
        ),
      );
    }
  }

  Future<String> _getOrCreateRecoveryKey(BuildContext context) async {
    return CryptoUtil.bin2hex(
      await UserService.instance.getOrCreateRecoveryKey(context),
    );
  }

  Future<void> _onDeleteAccountTapped(BuildContext context) async {
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      AppLocalizations.of(context).authToInitiateAccountDeletion,
    );
    if (hasAuthenticated) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const DeleteAccountPage();
            },
          ),
        ),
      );
    }
  }
}
