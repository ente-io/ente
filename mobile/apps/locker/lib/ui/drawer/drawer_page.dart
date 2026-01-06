import "package:ente_accounts/services/user_service.dart";
import "package:ente_events/event_bus.dart";
import "package:ente_sharing/verify_identity_dialog.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/events/user_details_refresh_event.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/legacy_collections_trash_widget.dart";
import "package:locker/ui/components/usage_card_widget.dart";
import "package:locker/ui/drawer/app_version_widget.dart";
import "package:locker/ui/drawer/drawer_title_bar_widget.dart";
import "package:locker/ui/drawer/settings_widgets.dart";

class DrawerPage extends StatelessWidget {
  final ValueNotifier<String?> emailNotifier;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const DrawerPage({
    super.key,
    required this.emailNotifier,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    Bus.instance.fire(UserDetailsRefreshEvent());

    final hasLoggedIn = Configuration.instance.hasConfiguredAccount();
    if (hasLoggedIn) {
      UserService.instance.getUserDetailsV2().ignore();
    }
    final enteColorScheme = getEnteColorScheme(context);
    return Scaffold(
      backgroundColor: enteColorScheme.backgroundBase,
      body: Container(
        color: enteColorScheme.backgroundBase,
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
        GestureDetector(
          onDoubleTap: () => showVerifyIdentitySheet(
            context,
            self: true,
            config: Configuration.instance,
            title: context.strings.verifyIDLabel,
          ),
          onLongPress: () => showVerifyIdentitySheet(
            context,
            self: true,
            config: Configuration.instance,
            title: context.strings.verifyIDLabel,
          ),
          child: Container(
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
        ),
      );
      contents.addAll([
        const SizedBox(height: 12),
        const UsageCardWidget(),
        const SizedBox(height: 12),
        const LegacyCollectionsTrashWidget(),
        sectionSpacing,
      ]);
    }

    contents.addAll([
      SettingsWidgets(hasLoggedIn: hasLoggedIn),
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
            DrawerTitleBarWidget(
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
