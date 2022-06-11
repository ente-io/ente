import 'dart:io';

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
    final String email = Configuration.instance.getEmail();
    final List<Widget> contents = [];
    contents.add(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              email,
              style: Theme.of(context)
                  .textTheme
                  .subtitle1
                  .copyWith(overflow: TextOverflow.ellipsis),
            ),
            (kDebugMode && Platform.isAndroid)
                ? ThemeSwitchWidget()
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
    final sectionDivider = Divider(
      height: 20,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
    );
    contents.add(Padding(padding: EdgeInsets.all(4)));
    if (hasLoggedIn) {
      contents.addAll([
        DetailsSectionWidget(),
        Padding(padding: EdgeInsets.only(bottom: 24)),
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

    if (kDebugMode && hasLoggedIn) {
      contents.addAll([sectionDivider, DebugSectionWidget()]);
    }
    contents.add(AppVersionWidget());
    contents.add(
      Padding(
        padding: EdgeInsets.only(bottom: 60),
      ),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
        child: Column(
          children: contents,
        ),
      ),
    );
  }
}
