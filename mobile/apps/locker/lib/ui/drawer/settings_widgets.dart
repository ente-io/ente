import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:locker/ui/drawer/about_section_widget.dart";
import "package:locker/ui/drawer/account_section_widget.dart";
import "package:locker/ui/drawer/general_section_widget.dart";
import "package:locker/ui/drawer/security_section_widget.dart";
import "package:locker/ui/drawer/social_section_widget.dart";
import "package:locker/ui/drawer/support_section_widget.dart";
import "package:locker/ui/drawer/theme_switch_widget.dart";

class SettingsWidgets extends StatelessWidget {
  final bool hasLoggedIn;

  const SettingsWidgets({
    super.key,
    required this.hasLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    const sectionSpacing = SizedBox(height: 8);
    final List<Widget> contents = [];

    if (hasLoggedIn) {
      contents.addAll([
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
      const GeneralSectionWidget(),
      sectionSpacing,
    ]);

    contents.addAll([
      const SupportSectionWidget(),
      sectionSpacing,
      const SocialSectionWidget(),
      sectionSpacing,
      const AboutSectionWidget(),
    ]);

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contents,
    );
  }
}
