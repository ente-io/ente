import "dart:io";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/error-reporting/super_logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/web_page.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/utils/email_util.dart";
import "package:url_launcher/url_launcher_string.dart";

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    final String bugsEmail =
        Platform.isAndroid ? "android-bugs@ente.io" : "ios-bugs@ente.io";

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
                AppLocalizations.of(context).support,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).help,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedHelpCircle,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) {
                                return WebPage(
                                  AppLocalizations.of(context).help,
                                  "https://ente.io/help",
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).reportABug,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedBug02,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await sendLogs(
                            context,
                            AppLocalizations.of(context).reportBug,
                            bugsEmail,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).contactSupport,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedMail01,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await sendEmail(context, to: supportEmail);
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).suggestFeatures,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedIdea01,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await launchUrlString(
                            githubDiscussionsUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).crashReporting,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedAlert02,
                        ),
                        trailingWidget: ToggleSwitchWidget(
                          value: () => SuperLogging.shouldReportCrashes(),
                          onChanged: () async {
                            await SuperLogging.setShouldReportCrashes(
                              !SuperLogging.shouldReportCrashes(),
                            );
                          },
                        ),
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
}
