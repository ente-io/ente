import "dart:io";

import "package:ente_accounts/services/user_service.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/settings/about_section_widget.dart";
import 'package:locker/ui/settings/account_section_widget.dart';
import "package:locker/ui/settings/app_version_widget.dart";
import "package:locker/ui/settings/security_section_widget.dart";
import "package:locker/ui/settings/social_section_widget.dart";
import "package:locker/ui/settings/support_section_widget.dart";
import "package:locker/ui/settings/theme_switch_widget.dart";
import "package:locker/ui/settings/title_bar_widget.dart";

class SettingsPage extends StatelessWidget {
  final ValueNotifier<String?> emailNotifier;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const SettingsPage({
    super.key,
    required this.emailNotifier,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final hasLoggedIn = Configuration.instance.hasConfiguredAccount();
    if (hasLoggedIn) {
      UserService.instance.getUserDetailsV2().ignore();
    }
    final enteColorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: Container(
        color: enteColorScheme.backdropBase,
        child: _getBody(context, enteColorScheme),
      ),
    );
  }

  Widget _getBody(BuildContext context, EnteColorScheme colorScheme) {
    final hasLoggedIn = Configuration.instance.hasConfiguredAccount();
    final enteTextTheme = getEnteTextTheme(context);
    const sectionSpacing = SizedBox(height: 8);
    final List<Widget> contents = [];

    if (hasLoggedIn) {
      contents.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              // [AnimatedBuilder] accepts any [Listenable] subtype.
              animation: emailNotifier,
              builder: (BuildContext context, Widget? child) {
                return Text(
                  emailNotifier.value!,
                  style: enteTextTheme.body.copyWith(
                    color: colorScheme.textMuted,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
      );
      contents.addAll([
        const SizedBox(height: 12),
        const AccountSectionWidget(),
        sectionSpacing,
      ]);

      contents.addAll([
        const SecuritySectionWidget(),
        sectionSpacing,
      ]);

      if (Platform.isAndroid ||
          Platform.isWindows ||
          Platform.isLinux ||
          kDebugMode) {
        contents.addAll([
          const ThemeSwitchWidget(),
          sectionSpacing,
        ]);
      }
    }

    contents.addAll([
      const SupportSectionWidget(),
      sectionSpacing,
      const SocialSectionWidget(),
      sectionSpacing,
      const AboutSectionWidget(),
      const AppVersionWidget(),
      const Padding(
        padding: EdgeInsets.only(bottom: 60),
      ),
    ]);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsTitleBarWidget(
              scaffoldKey: scaffoldKey,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: contents,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
