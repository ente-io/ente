import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/web_page.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/settings/settings_grouped_card.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/settings/app_update_dialog.dart";
import "package:photos/utils/dialog_util.dart";
import "package:url_launcher/url_launcher.dart";

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.strokeBase,
                  size: 24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).about,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SettingsGroupedCard(
                        children: [
                          MenuItemWidgetNew(
                            title: AppLocalizations.of(context).weAreOpenSource,
                            leadingIconWidget: _buildIconWidget(
                              context,
                              HugeIcons.strokeRoundedGithub,
                            ),
                            trailingIcon: Icons.chevron_right_outlined,
                            trailingIconIsMuted: true,
                            onTap: () async {
                              await launchUrl(
                                Uri.parse("https://github.com/ente-io/ente"),
                              );
                            },
                          ),
                          MenuItemWidgetNew(
                            title: AppLocalizations.of(context).blog,
                            leadingIconWidget: _buildIconWidget(
                              context,
                              HugeIcons.strokeRoundedPencilEdit01,
                            ),
                            trailingIcon: Icons.chevron_right_outlined,
                            trailingIconIsMuted: true,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return WebPage(
                                      AppLocalizations.of(context).blog,
                                      "https://ente.io/blog",
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          MenuItemWidgetNew(
                            title: AppLocalizations.of(context).privacy,
                            leadingIconWidget: _buildIconWidget(
                              context,
                              HugeIcons.strokeRoundedShield01,
                            ),
                            trailingIcon: Icons.chevron_right_outlined,
                            trailingIconIsMuted: true,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return WebPage(
                                      AppLocalizations.of(context).privacy,
                                      "https://ente.io/privacy",
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          MenuItemWidgetNew(
                            title: AppLocalizations.of(context)
                                .termsOfServicesTitle,
                            leadingIconWidget: _buildIconWidget(
                              context,
                              HugeIcons.strokeRoundedFile01,
                            ),
                            trailingIcon: Icons.chevron_right_outlined,
                            trailingIconIsMuted: true,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return WebPage(
                                      AppLocalizations.of(context)
                                          .termsOfServicesTitle,
                                      "https://ente.io/terms",
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          if (updateService.isIndependent())
                            MenuItemWidgetNew(
                              title:
                                  AppLocalizations.of(context).checkForUpdates,
                              leadingIconWidget: _buildIconWidget(
                                context,
                                HugeIcons.strokeRoundedDownload04,
                              ),
                              trailingIcon: Icons.chevron_right_outlined,
                              trailingIconIsMuted: true,
                              onTap: () async => _checkForUpdates(context),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconWidget(BuildContext context, List<List<dynamic>> icon) {
    final colorScheme = getEnteColorScheme(context);
    return HugeIcon(
      icon: icon,
      color: colorScheme.strokeBase,
      size: 20,
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    final dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).checking,
    );
    await dialog.show();
    final shouldUpdate = await updateService.shouldUpdate();
    await dialog.hide();
    if (shouldUpdate) {
      await showDialog(
        useRootNavigator: false,
        context: context,
        builder: (BuildContext context) {
          return AppUpdateDialog(
            updateService.getLatestVersionInfo(),
          );
        },
        barrierColor: Colors.black.withValues(alpha: 0.85),
      );
    } else {
      showShortToast(
        context,
        AppLocalizations.of(context).youAreOnTheLatestVersion,
      );
    }
  }
}
