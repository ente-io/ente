import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/settings/account_section_widget.dart';
import 'package:photos/ui/settings/app_version_widget.dart';
import 'package:photos/ui/settings/backup_section_widget.dart';
import 'package:photos/ui/settings/danger_section_widget.dart';
import 'package:photos/ui/settings/debug_section_widget.dart';
import 'package:photos/ui/settings/details_section_widget.dart';
import 'package:photos/ui/settings/info_section_widget.dart';
import 'package:photos/ui/settings/security_section_widget.dart';
import 'package:photos/ui/settings/social_section_widget.dart';
import 'package:photos/ui/settings/support_section_widget.dart';
import 'package:photos/ui/settings/theme_switch_widget.dart';
import 'package:photos/ui/settings/usage_details_widget.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getBody(context),
    );
  }

  Widget _getBody(BuildContext context) {
    final hasLoggedIn = Configuration.instance.getToken() != null;
    final List<Widget> contents = [];
    contents.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [ThemeSwitchWidget()]));
    final sectionDivider = Divider(
      height: 10,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
    );
    if (hasLoggedIn) {
      contents.addAll([
        DetailsSectionWidget(),
        sectionDivider,
        UsageDetailsWidget(),
        sectionDivider,
        BackupSectionWidget(),
        sectionDivider,
        AccountSectionWidget(),
        sectionDivider,
      ]);
    }
    contents.addAll([
      SecuritySectionWidget(),
      sectionDivider,
      SupportSectionWidget(),
      sectionDivider,
      SocialSectionWidget(),
      sectionDivider,
      InfoSectionWidget(),
    ]);
    if (hasLoggedIn) {
      contents.addAll([
        sectionDivider,
        DangerSectionWidget(),
      ]);
    }
    contents.add(AppVersionWidget());
    if (kDebugMode && hasLoggedIn) {
      contents.add(DebugSectionWidget());
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: contents,
        ),
      ),
    );
  }
}
