import "package:ente_accounts/services/user_service.dart";
import "package:ente_ui/components/alert_bottom_sheet.dart";
import "package:ente_ui/components/buttons/gradient_button.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/settings/pages/about_page.dart";
import "package:locker/ui/settings/pages/account_settings_page.dart";
import "package:locker/ui/settings/pages/general_settings_page.dart";
import "package:locker/ui/settings/pages/security_settings_page.dart";
import "package:locker/ui/settings/pages/support_page.dart";
import "package:locker/ui/settings/pages/theme_settings_page.dart";
import "package:locker/ui/settings/widgets/app_version_widget.dart";
import "package:locker/ui/settings/widgets/settings_widget.dart";
import "package:locker/ui/settings/widgets/social_icons_row.dart";

class SettingsWidget extends StatelessWidget {
  final bool hasLoggedIn;

  const SettingsWidget({
    required this.hasLoggedIn,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const itemSpacing = SizedBox(height: 8);

    final List<Widget> contents = [];

    if (hasLoggedIn) {
      contents.add(
        SettingsItem(
          icon: HugeIcons.strokeRoundedUser,
          title: l10n.account,
          onTap: () => _navigateTo(context, const AccountSettingsPage()),
        ),
      );
      contents.add(itemSpacing);

      contents.add(
        SettingsItem(
          icon: HugeIcons.strokeRoundedSecurityCheck,
          title: l10n.security,
          onTap: () => _navigateTo(context, const SecuritySettingsPage()),
        ),
      );
      contents.add(itemSpacing);

      contents.add(
        SettingsItem(
          icon: HugeIcons.strokeRoundedSun03,
          title: l10n.appearance,
          onTap: () => _navigateTo(context, const ThemeSettingsPage()),
        ),
      );
      contents.add(itemSpacing);
    }

    contents.add(
      SettingsItem(
        icon: HugeIcons.strokeRoundedSettings01,
        title: l10n.general,
        onTap: () => _onGeneralTapped(context),
      ),
    );
    contents.add(itemSpacing);

    contents.add(
      SettingsItem(
        icon: HugeIcons.strokeRoundedHelpCircle,
        title: l10n.helpAndSupport,
        onTap: () => _navigateTo(context, const SupportPage()),
      ),
    );
    contents.add(itemSpacing);

    contents.add(
      SettingsItem(
        icon: HugeIcons.strokeRoundedInformationCircle,
        title: l10n.aboutUs,
        onTap: () => _navigateTo(context, const AboutPage()),
      ),
    );

    if (hasLoggedIn) {
      contents.add(itemSpacing);
      contents.add(
        SettingsItem(
          icon: HugeIcons.strokeRoundedLogout05,
          title: l10n.logout,
          iconColor: getEnteColorScheme(context).warning400,
          textColor: getEnteColorScheme(context).warning400,
          onTap: () => _onLogoutTapped(context),
        ),
      );
    }

    contents.addAll([
      const SizedBox(height: 24),
      const SocialIconsRow(),
      const AppVersionWidget(),
    ]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contents,
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _onGeneralTapped(BuildContext context) {
    _navigateTo(context, const GeneralSettingsPage());
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
