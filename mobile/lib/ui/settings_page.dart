import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/opened_settings_event.dart';
import "package:photos/service_locator.dart";
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/settings/about_section_widget.dart';
import 'package:photos/ui/settings/app_version_widget.dart';
import 'package:photos/ui/settings/backup/backup_section_widget.dart';
import 'package:photos/ui/settings/debug/debug_section_widget.dart';
import "package:photos/ui/settings/debug/ml_debug_section_widget.dart";
import 'package:photos/ui/settings/general_section_widget.dart';
import 'package:photos/ui/settings/inherited_settings_state.dart';
import 'package:photos/ui/settings/security_section_widget.dart';
import 'package:photos/ui/settings/settings_title_bar_widget.dart';
import 'package:photos/ui/settings/storage_card_widget.dart';
import 'package:photos/ui/settings/support_section_widget.dart';
import 'package:photos/ui/settings/theme_switch_widget.dart';
import "package:photos/ui/sharing/verify_identity_dialog.dart";
import 'package:photos/utils/email_util.dart';

class SettingsPage extends StatelessWidget {
  final ValueNotifier<String?> emailNotifier;

  const SettingsPage({super.key, required this.emailNotifier});

  @override
  Widget build(BuildContext context) {
    Bus.instance.fire(OpenedSettingsEvent());
    final enteColorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: Container(
        color: enteColorScheme.backdropMuted,
        child: SettingsStateContainer(
          child: _getBody(context, enteColorScheme),
        ),
      ),
    );
  }

  Widget _getBody(BuildContext context, EnteColorScheme colorScheme) {
    final hasLoggedIn = Configuration.instance.isLoggedIn();
    final enteTextTheme = getEnteTextTheme(context);
    final List<Widget> contents = [];
    const sectionSpacing = SizedBox(height: 8);
    contents.add(
      GestureDetector(
        onDoubleTap: () {
          _showVerifyIdentityDialog(context);
        },
        onLongPress: () {
          _showVerifyIdentityDialog(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              // [AnimatedBuilder] accepts any [Listenable] subtype.
              animation: emailNotifier,
              builder: (BuildContext context, Widget? child) {
                return Text(
                  getUsernameFromEmail(emailNotifier.value!),
                  style: enteTextTheme.body.copyWith(
                    color: colorScheme.textMuted,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    contents.add(const SizedBox(height: 8));
    if (hasLoggedIn) {
      contents.addAll([
        const StorageCardWidget(),
        const SizedBox(height: 16), // Add margin between storage card and backup section
        const BackupSectionWidget(),
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
      const AboutSectionWidget(),
    ]);

    if (hasLoggedIn && flagService.internalUser) {
      contents.addAll([sectionSpacing, const DebugSectionWidget()]);
      contents.addAll([sectionSpacing, const MLDebugSectionWidget()]);
    }
    contents.add(const AppVersionWidget());
    // contents.add(const DeveloperSettingsWidget());
    contents.add(
      const Padding(
        padding: EdgeInsets.only(bottom: 60),
      ),
    );

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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

  Future<void> _showVerifyIdentityDialog(BuildContext context) async {
    await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return VerifyIdentifyDialog(self: true);
      },
    );
  }
}
