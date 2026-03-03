import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:log_viewer/log_viewer.dart";
import "package:photos/core/configuration.dart";
import "package:photos/emergency/emergency_page.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/services/local_authentication_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/account/login_page.dart";
import "package:photos/ui/components/banners/offline_settings_banner.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/settings/settings_grouped_card.dart";
import "package:photos/ui/components/settings/social_icons_row.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/growth/referral_screen.dart";
import "package:photos/ui/home/landing_page_widget.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/settings/about/about_us_page.dart";
import "package:photos/ui/settings/account/account_settings_page.dart";
import "package:photos/ui/settings/app_version_widget.dart";
import "package:photos/ui/settings/appearance/appearance_settings_page.dart";
import "package:photos/ui/settings/backup/backup_settings_page.dart";
import "package:photos/ui/settings/backup/free_space_options.dart";
import "package:photos/ui/settings/debug/debug_settings_page.dart";
import "package:photos/ui/settings/debug/ml_debug_settings_page.dart";
import "package:photos/ui/settings/inherited_settings_state.dart";
import "package:photos/ui/settings/memories_settings_screen.dart";
import "package:photos/ui/settings/ml/machine_learning_settings_page.dart";
import "package:photos/ui/settings/notification_settings_screen.dart";
import "package:photos/ui/settings/search/settings_search_page.dart";
import "package:photos/ui/settings/security/security_settings_page.dart";
import "package:photos/ui/settings/storage_card_widget.dart";
import "package:photos/ui/settings/streaming/video_streaming_settings_page.dart";
import "package:photos/ui/settings/support/help_support_page.dart";
import "package:photos/ui/settings/widget_settings_screen.dart";
import "package:photos/ui/sharing/verify_identity_dialog.dart";
import "package:photos/utils/dialog_util.dart";
import "package:url_launcher/url_launcher_string.dart";

class SettingsPage extends StatelessWidget {
  final ValueNotifier<String?> emailNotifier;

  const SettingsPage({super.key, required this.emailNotifier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettingsStateContainer(
        child: _SettingsBody(emailNotifier: emailNotifier),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  final ValueNotifier<String?> emailNotifier;

  const _SettingsBody({required this.emailNotifier});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasLoggedIn = Configuration.instance.isLoggedIn();
    final hasConfiguredAccount = Configuration.instance.hasConfiguredAccount();
    final showLoginEntry = isOfflineMode && !hasConfiguredAccount;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Container(
      color: pageBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleBar(context, colorScheme),
                if (hasLoggedIn)
                  _buildEmailHeaderSection(context, colorScheme, textTheme)
                else
                  const SizedBox(height: 8),
                if (showLoginEntry) ...[
                  OfflineSettingsBanner(
                    onGetStarted: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LandingPageWidget(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildOfflineLoginCard(context, colorScheme),
                  const SizedBox(height: 8),
                ],
                if (hasLoggedIn && !isOfflineMode) ...[
                  const StorageCardWidget(),
                  const SizedBox(height: 16),
                  _buildAccountCard(context, colorScheme),
                  const SizedBox(height: 8),
                  _buildBackupCard(context, colorScheme),
                  const SizedBox(height: 8),
                ],
                _buildSecurityCard(context, colorScheme),
                const SizedBox(height: 8),
                _buildAppearanceCard(context, colorScheme),
                const SizedBox(height: 8),
                if (isOfflineMode) ...[
                  _buildOfflineFeaturesCard(context, colorScheme),
                  const SizedBox(height: 8),
                ],
                if (hasLoggedIn && !isOfflineMode) ...[
                  _buildPersonalFeaturesCard(context, colorScheme),
                  const SizedBox(height: 8),
                  _buildFeaturesAndPlansCard(context, colorScheme),
                  const SizedBox(height: 8),
                ],
                _buildEngagementCard(context, colorScheme),
                const SizedBox(height: 8),
                _buildHelpSupportCard(context, colorScheme),
                const SizedBox(height: 8),
                _buildAboutUsCard(context, colorScheme),
                const SizedBox(height: 8),
                if (hasLoggedIn && !isOfflineMode) ...[
                  _buildLogoutCard(context, colorScheme),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: SocialIconsRow(),
                ),
                const AppVersionWidget(),
                if (hasLoggedIn &&
                    !isOfflineMode &&
                    (flagService.flags.internalUser || kDebugMode)) ...[
                  _buildDebugCard(context, colorScheme),
                  const SizedBox(height: 8),
                  _buildMLDebugCard(context, colorScheme),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context, EnteColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.keyboard_double_arrow_left,
              size: 24,
              color: colorScheme.textBase,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: const EdgeInsets.all(8),
              iconSize: 20,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsSearchPage(),
                  ),
                );
              },
              icon: Icon(
                Icons.search_rounded,
                color: colorScheme.textMuted,
              ),
            ),
            if (localSettings.enableDatabaseLogging)
              IconButton(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: const EdgeInsets.all(8),
                iconSize: 20,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LogViewerPage(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.bug_report,
                  color: colorScheme.textMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailHeader(
    BuildContext context,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return GestureDetector(
      onDoubleTap: () => _showVerifyIdentityDialog(context),
      onLongPress: () => _showVerifyIdentityDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: AnimatedBuilder(
          animation: emailNotifier,
          builder: (BuildContext context, Widget? child) {
            return Text(
              emailNotifier.value ?? "",
              style: textTheme.body.copyWith(
                color: colorScheme.textMuted,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmailHeaderSection(
    BuildContext context,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return AnimatedBuilder(
      animation: emailNotifier,
      builder: (BuildContext context, Widget? child) {
        final email = emailNotifier.value ?? "";
        if (email.isEmpty) {
          return const SizedBox(height: 8);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildEmailHeader(context, colorScheme, textTheme),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildIconWidget(
    List<List<dynamic>> icon,
    EnteColorScheme colorScheme, {
    bool isDestructive = false,
  }) {
    return HugeIcon(
      icon: icon,
      color: isDestructive
          ? colorScheme.warning700
          : colorScheme.menuItemIconStroke,
      size: 20,
    );
  }

  Widget _buildAccountCard(BuildContext context, EnteColorScheme colorScheme) {
    return MenuItemWidgetNew(
      title: AppLocalizations.of(context).account,
      leadingIconWidget: _buildIconWidget(
        HugeIcons.strokeRoundedUser,
        colorScheme,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        await routeToPage(context, const AccountSettingsPage());
      },
    );
  }

  Widget _buildBackupCard(BuildContext context, EnteColorScheme colorScheme) {
    return MenuItemWidgetNew(
      title: AppLocalizations.of(context).backup,
      leadingIconWidget: _buildIconWidget(
        HugeIcons.strokeRoundedCloudUpload,
        colorScheme,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        await routeToPage(context, const BackupSettingsPage());
      },
    );
  }

  Widget _buildOfflineLoginCard(
    BuildContext context,
    EnteColorScheme colorScheme,
  ) {
    return MenuItemWidgetNew(
      title: AppLocalizations.of(context).alreadyHaveAnAccount,
      subText: AppLocalizations.of(context).loginToEnte,
      leadingIconWidget: _buildIconWidget(
        HugeIcons.strokeRoundedLogin01,
        colorScheme,
      ),
      trailingWidget: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.greenBase,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: contentReverseLight,
          size: 20,
        ),
      ),
      onTap: () async {
        await routeToPage(context, const LoginPage());
      },
    );
  }

  Widget _buildOfflineFeaturesCard(
    BuildContext context,
    EnteColorScheme colorScheme,
  ) {
    return SettingsGroupedCard(
      children: [
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).machineLearning,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedMagicWand01,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await routeToPage(context, const MachineLearningSettingsPage());
          },
        ),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).memories,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedSparkles,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await routeToPage(context, const MemoriesSettingsScreen());
          },
        ),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).notifications,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedNotification01,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await routeToPage(context, const NotificationSettingsScreen());
          },
        ),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).widgets,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedAlignBoxBottomRight,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await routeToPage(context, const WidgetSettingsScreen());
          },
        ),
        _buildMapsMenuItem(context, colorScheme),
      ],
    );
  }

  Widget _buildSecurityCard(BuildContext context, EnteColorScheme colorScheme) {
    return MenuItemWidgetNew(
      title: AppLocalizations.of(context).security,
      leadingIconWidget: _buildIconWidget(
        HugeIcons.strokeRoundedSecurityCheck,
        colorScheme,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        await routeToPage(context, const SecuritySettingsPage());
      },
    );
  }

  Widget _buildAppearanceCard(
    BuildContext context,
    EnteColorScheme colorScheme,
  ) {
    return MenuItemWidgetNew(
      title: AppLocalizations.of(context).appearance,
      leadingIconWidget: _buildIconWidget(
        HugeIcons.strokeRoundedPaintBoard,
        colorScheme,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        await routeToPage(context, const AppearanceSettingsPage());
      },
    );
  }

  Widget _buildPersonalFeaturesCard(
    BuildContext context,
    EnteColorScheme colorScheme,
  ) {
    return SettingsGroupedCard(
      children: [
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).legacy,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedFavourite,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          showOnlyLoadingState: true,
          onTap: () async {
            final hasAuthenticated = kDebugMode ||
                await LocalAuthenticationService.instance
                    .requestLocalAuthentication(
                  context,
                  AppLocalizations.of(context).authToManageLegacy,
                );
            if (hasAuthenticated) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const EmergencyPage();
                  },
                ),
              );
            }
          },
        ),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).familyPlans,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedUserMultiple,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          showOnlyLoadingState: true,
          onTap: () async {
            final userDetails =
                await UserService.instance.getUserDetailsV2(memoryCount: false);
            await billingService.launchFamilyPortal(context, userDetails);
          },
        ),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).referrals,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedTicketStar,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await routeToPage(context, const ReferralScreen());
          },
        ),
      ],
    );
  }

  Widget _buildFeaturesAndPlansCard(
    BuildContext context,
    EnteColorScheme colorScheme,
  ) {
    return SettingsGroupedCard(
      children: [
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).freeUpSpace,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedRocket01,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          showOnlyLoadingState: true,
          onTap: () async {
            await routeToPage(context, const FreeUpSpaceOptionsScreen());
          },
        ),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).machineLearning,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedMagicWand01,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await routeToPage(context, const MachineLearningSettingsPage());
          },
        ),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).memories,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedSparkles,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await routeToPage(context, const MemoriesSettingsScreen());
          },
        ),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).notifications,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedNotification01,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await routeToPage(context, const NotificationSettingsScreen());
          },
        ),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).widgets,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedAlignBoxBottomRight,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await routeToPage(context, const WidgetSettingsScreen());
          },
        ),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).videoStreaming,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedVideoCameraAi,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await routeToPage(context, const VideoStreamingSettingsPage());
          },
        ),
        _buildMapsMenuItem(context, colorScheme),
      ],
    );
  }

  Widget _buildMapsMenuItem(BuildContext context, EnteColorScheme colorScheme) {
    return MenuItemWidgetNew(
      title: AppLocalizations.of(context).maps,
      borderRadius: 0,
      leadingIconWidget: _buildIconWidget(
        HugeIcons.strokeRoundedMaping,
        colorScheme,
      ),
      trailingWidget: ToggleSwitchWidget(
        value: () => mapEnabled,
        onChanged: () async {
          final isEnabled = mapEnabled;
          try {
            await setMapEnabled(!isEnabled);
          } catch (e) {
            showShortToast(
              context,
              AppLocalizations.of(context).somethingWentWrong,
            );
            rethrow;
          }
        },
      ),
    );
  }

  Widget _buildEngagementCard(
    BuildContext context,
    EnteColorScheme colorScheme,
  ) {
    return SettingsGroupedCard(
      children: [
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).merchandise,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedTShirt,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            await launchUrlString(
              "https://shop.ente.io",
              mode: LaunchMode.externalApplication,
            );
          },
        ),
        MenuItemWidgetNew(
          title: AppLocalizations.of(context).rateUs,
          borderRadius: 0,
          leadingIconWidget: _buildIconWidget(
            HugeIcons.strokeRoundedStar,
            colorScheme,
          ),
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            final rateUrl = updateService.getRateDetails().item2;
            await launchUrlString(rateUrl);
          },
        ),
      ],
    );
  }

  Widget _buildHelpSupportCard(
    BuildContext context,
    EnteColorScheme colorScheme,
  ) {
    return MenuItemWidgetNew(
      title: AppLocalizations.of(context).helpAndSupport,
      leadingIconWidget: _buildIconWidget(
        HugeIcons.strokeRoundedHelpCircle,
        colorScheme,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        await routeToPage(context, const HelpSupportPage());
      },
    );
  }

  Widget _buildAboutUsCard(BuildContext context, EnteColorScheme colorScheme) {
    return MenuItemWidgetNew(
      title: AppLocalizations.of(context).about,
      leadingIconWidget: _buildIconWidget(
        HugeIcons.strokeRoundedInformationCircle,
        colorScheme,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        await routeToPage(context, const AboutUsPage());
      },
    );
  }

  Widget _buildLogoutCard(BuildContext context, EnteColorScheme colorScheme) {
    return MenuItemWidgetNew(
      title: AppLocalizations.of(context).logout,
      titleColor: colorScheme.warning700,
      leadingIconWidget: _buildIconWidget(
        HugeIcons.strokeRoundedLogout05,
        colorScheme,
        isDestructive: true,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        _onLogoutTapped(context);
      },
    );
  }

  void _onLogoutTapped(BuildContext context) {
    showChoiceActionSheet(
      context,
      title: AppLocalizations.of(context).areYouSureYouWantToLogout,
      firstButtonLabel: AppLocalizations.of(context).yesLogout,
      isCritical: true,
      firstButtonOnTap: () async {
        await UserService.instance.logout(context);
      },
    );
  }

  Widget _buildDebugCard(BuildContext context, EnteColorScheme colorScheme) {
    return MenuItemWidgetNew(
      title: "Debug",
      leadingIconWidget: _buildIconWidget(
        HugeIcons.strokeRoundedBug02,
        colorScheme,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        await routeToPage(context, const DebugSettingsPage());
      },
    );
  }

  Widget _buildMLDebugCard(BuildContext context, EnteColorScheme colorScheme) {
    return MenuItemWidgetNew(
      title: "ML Debug",
      leadingIconWidget: _buildIconWidget(
        HugeIcons.strokeRoundedAiBrain01,
        colorScheme,
      ),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        await routeToPage(context, const MLDebugSettingsPage());
      },
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
