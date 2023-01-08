// @dart=2.9

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/account/sessions_page.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/components/toggle_switch_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:flutter/material.dart';

class SecuritySectionWidget extends StatefulWidget {
  const SecuritySectionWidget({Key key}) : super(key: key);

  @override
  State<SecuritySectionWidget> createState() => _SecuritySectionWidgetState();
}

class _SecuritySectionWidgetState extends State<SecuritySectionWidget> {
  final _config = Configuration.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "Security",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.local_police_outlined,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;
    final List<Widget> children = [];
    children.addAll([
      MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          title: "Lockscreen",
        ),
        trailingSwitch: ToggleSwitchWidget(
          value: _config.shouldShowLockScreen(),
          onChanged: (value) async {
            final hasAuthenticated = await LocalAuthenticationService.instance
                .requestLocalAuthForLockScreen(
              context,
              value,
              "Please authenticate to change lockscreen setting",
              "To enable lockscreen, please setup device passcode or screen lock in your system settings.",
            );
            if (hasAuthenticated) {
              setState(() {});
            }
          },
        ),
      ),
      sectionOptionSpacing,
      MenuItemWidget(
        captionedTextWidget: const CaptionedTextWidget(
          title: "Active sessions",
        ),
        pressedColor: getEnteColorScheme(context).fillFaint,
        trailingIcon: Icons.chevron_right_outlined,
        trailingIconIsMuted: true,
        onTap: () async {
          final hasAuthenticated = await LocalAuthenticationService.instance
              .requestLocalAuthentication(
            context,
            "Please authenticate to view your active sessions",
          );
          if (hasAuthenticated) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const SessionsPage();
                },
              ),
            );
          }
        },
      ),
      sectionOptionSpacing,
    ]);
    return Column(
      children: children,
    );
  }
}
