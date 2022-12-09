// @dart=2.9

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/feature_flag_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/settings/about_section_widget.dart';
import 'package:photos/ui/settings/account_section_widget.dart';
import 'package:photos/ui/settings/app_version_widget.dart';
import 'package:photos/ui/settings/backup_section_widget.dart';
import 'package:photos/ui/settings/debug_section_widget.dart';
import 'package:photos/ui/settings/general_section_widget.dart';
import 'package:photos/ui/settings/security_section_widget.dart';
import 'package:photos/ui/settings/settings_title_bar_widget.dart';
import 'package:photos/ui/settings/social_section_widget.dart';
import 'package:photos/ui/settings/storage_card_widget.dart';
import 'package:photos/ui/settings/support_section_widget.dart';
import 'package:photos/ui/settings/theme_switch_widget.dart';

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
    final hasLoggedIn = Configuration.instance.isLoggedIn();
    final enteTextTheme = getEnteTextTheme(context);
    final List<Widget> contents = [];
    contents.add(
      Container(
        constraints: const BoxConstraints(maxWidth: 350),
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
    contents.add(const SizedBox(height: 8));
    if (hasLoggedIn) {
      contents.addAll([
        const StorageCardWidget(),
        const SizedBox(height: 12),
        const BackupSectionWidget(),
        sectionSpacing,
        const AccountSectionWidget(),
        sectionSpacing,
      ]);
    }
    contents.addAll([
      const SecuritySectionWidget(),
      sectionSpacing,
      const GeneralSectionWidget(),
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
    ]);

    if (FeatureFlagService.instance.isInternalUserOrDebugBuild() &&
        hasLoggedIn) {
      contents.addAll([sectionSpacing, const DebugSectionWidget()]);
    }
    contents.add(const AppVersionWidget());
    contents.add(
      const Padding(
        padding: EdgeInsets.only(bottom: 60),
      ),
    );

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
