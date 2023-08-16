import 'dart:io';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/theme/colors.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/settings/about_section_widget.dart';
import 'package:ente_auth/ui/settings/account_section_widget.dart';
import 'package:ente_auth/ui/settings/app_version_widget.dart';
import 'package:ente_auth/ui/settings/data/data_section_widget.dart';
import 'package:ente_auth/ui/settings/security_section_widget.dart';
import 'package:ente_auth/ui/settings/social_section_widget.dart';
import 'package:ente_auth/ui/settings/support_dev_widget.dart';
import 'package:ente_auth/ui/settings/support_section_widget.dart';
import 'package:ente_auth/ui/settings/theme_switch_widget.dart';
import 'package:ente_auth/ui/settings/title_bar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final ValueNotifier<String?> emailNotifier;
  final _hasLoggedIn = Configuration.instance.hasConfiguredAccount();

  SettingsPage({Key? key, required this.emailNotifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (_hasLoggedIn) {
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
    final enteTextTheme = getEnteTextTheme(context);
    const sectionSpacing = SizedBox(height: 8);
    final List<Widget> contents = [];
    if (_hasLoggedIn) {
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
        AccountSectionWidget(),
        sectionSpacing,
      ]);
    }
    contents.addAll([
      DataSectionWidget(),
      sectionSpacing,
      const SecuritySectionWidget(),
      sectionSpacing,
    ]);

    if (Platform.isAndroid || kDebugMode) {
      contents.addAll([
        const ThemeSwitchWidget(),
        sectionSpacing,
      ]);
    }

    contents.addAll([
      const SupportSectionWidget(),
      sectionSpacing,
      const SocialSectionWidget(),
      sectionSpacing,
      const AboutSectionWidget(),
      const AppVersionWidget(),
      const SupportDevWidget(),
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
            const SettingsTitleBarWidget(),
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
