// @dart=2.9

import 'dart:io';

import 'package:ente_auth/theme/colors.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/settings/about_section_widget.dart';
import 'package:ente_auth/ui/settings/account_section_widget.dart';
import 'package:ente_auth/ui/settings/app_version_widget.dart';
import 'package:ente_auth/ui/settings/danger_section_widget.dart';
import 'package:ente_auth/ui/settings/made_with_love_widget.dart';
import 'package:ente_auth/ui/settings/security_section_widget.dart';
import 'package:ente_auth/ui/settings/social_section_widget.dart';
import 'package:ente_auth/ui/settings/support_section_widget.dart';
import 'package:ente_auth/ui/settings/theme_switch_widget.dart';
import 'package:ente_auth/ui/settings/title_bar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final ValueNotifier<String> emailNotifier;
  const SettingsPage({Key key, @required this.emailNotifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
    final List<Widget> contents = [];
    contents.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            // [AnimatedBuilder] accepts any [Listenable] subtype.
            animation: emailNotifier,
            builder: (BuildContext context, Widget child) {
              return Text(
                emailNotifier.value,
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
    const sectionSpacing = SizedBox(height: 8);
    contents.add(const SizedBox(height: 12));
    contents.addAll([
      AccountSectionWidget(),
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
      sectionSpacing,
      const DangerSectionWidget(),
      const AppVersionWidget(),
      const MadeWithLoveWidget(),
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
