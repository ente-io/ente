import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import "package:flutter_animate/flutter_animate.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/opened_settings_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/components/notification_widget.dart";
import "package:photos/ui/growth/referral_screen.dart";
import 'package:photos/ui/settings/about_section_widget.dart';
import 'package:photos/ui/settings/account_section_widget.dart';
import 'package:photos/ui/settings/app_version_widget.dart';
import 'package:photos/ui/settings/backup/backup_section_widget.dart';
import 'package:photos/ui/settings/debug/debug_section_widget.dart';
import "package:photos/ui/settings/debug/ml_debug_section_widget.dart";
import "package:photos/ui/settings/developer_settings_widget.dart";
import 'package:photos/ui/settings/general_section_widget.dart';
import 'package:photos/ui/settings/inherited_settings_state.dart';
import 'package:photos/ui/settings/security_section_widget.dart';
import 'package:photos/ui/settings/settings_title_bar_widget.dart';
import 'package:photos/ui/settings/social_section_widget.dart';
import 'package:photos/ui/settings/storage_card_widget.dart';
import 'package:photos/ui/settings/support_section_widget.dart';
import 'package:photos/ui/settings/theme_switch_widget.dart';
import "package:photos/ui/sharing/verify_identity_dialog.dart";
import "package:photos/utils/navigation_util.dart";

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

    contents.add(const SizedBox(height: 8));
    if (hasLoggedIn) {
      // show banner in debug mode and ente production
      final showStorageBonusBanner =
          storageBonusService.shouldShowStorageBonus() &&
              (kDebugMode || Configuration.instance.isEnteProduction());
      contents.addAll([
        const StorageCardWidget(),
        (showStorageBonusBanner)
            ? RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: NotificationWidget(
                    startIcon: Icons.auto_awesome,
                    actionIcon: Icons.arrow_forward_outlined,
                    text: AppLocalizations.of(context).doubleYourStorage,
                    subText:
                        AppLocalizations.of(context).referFriendsAnd2xYourPlan,
                    type: NotificationType.goldenBanner,
                    onTap: () async {
                      storageBonusService.markStorageBonusAsDone();
                      // ignore: unawaited_futures
                      routeToPage(context, const ReferralScreen());
                    },
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                      duration: 1000.ms,
                      delay: 3200.ms,
                      size: 0.6,
                    ),
              )
            : const SizedBox(height: 12),
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

    if (hasLoggedIn && flagService.internalUser) {
      contents.addAll([sectionSpacing, const DebugSectionWidget()]);
      contents.addAll([sectionSpacing, const MLDebugSectionWidget()]);
    }
    contents.add(const AppVersionWidget());
    contents.add(const DeveloperSettingsWidget());
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
