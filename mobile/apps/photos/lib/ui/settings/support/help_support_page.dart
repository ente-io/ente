import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/web_page.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/components/menu_section_title.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/settings/support/ask_question_page.dart";
import "package:photos/ui/settings/support/report_issue_page.dart";
import "package:photos/utils/email_util.dart";
import "package:url_launcher/url_launcher_string.dart";

class HelpSupportPage extends StatelessWidget {
  static final _logger = Logger("HelpSupportPage");
  static const _helpUrl = "https://ente.io/help";

  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                l10n.helpAndSupport,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MenuSectionTitle(title: l10n.browseHelpPages),
                      _buildHelpTopicItem(
                        context,
                        title: l10n.searchAndDiscovery,
                        subText: l10n.searchAndDiscoveryDesc,
                        icon: HugeIcons.strokeRoundedSearch01,
                      ),
                      const SizedBox(height: 8),
                      _buildHelpTopicItem(
                        context,
                        title: l10n.backupAndSync,
                        subText: l10n.backupAndSyncDesc,
                        icon: HugeIcons.strokeRoundedCloudUpload,
                      ),
                      const SizedBox(height: 8),
                      _buildHelpTopicItem(
                        context,
                        title: l10n.sharingAndCollaboration,
                        subText: l10n.sharingAndCollaborationDesc,
                        icon: HugeIcons.strokeRoundedShare01,
                      ),
                      const SizedBox(height: 8),
                      _buildHelpTopicItem(
                        context,
                        title: l10n.storageAndPlans,
                        subText: l10n.storageAndPlansDesc,
                        icon: HugeIcons.strokeRoundedHardDrive,
                      ),
                      const SizedBox(height: 8),
                      _buildHelpTopicItem(
                        context,
                        title: l10n.troubleshooting,
                        subText: l10n.troubleshootingDesc,
                        icon: HugeIcons.strokeRoundedWrench01,
                      ),
                      _SupportLink(
                        label: l10n.viewAllHelpTopics,
                        onTap: () async {
                          await _openHelpPage(
                            context,
                            title: l10n.helpAndSupport,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      MenuSectionTitle(title: l10n.getInTouch),
                      MenuItemWidgetNew(
                        title: l10n.reportAnIssue,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedBug02,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ReportIssuePage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: l10n.askAQuestion,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedHelpCircle,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AskQuestionPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: l10n.requestAFeature,
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
                      _SupportLink(
                        label: l10n.exportLogs,
                        onTap: () async {
                          await _exportLogs(context);
                        },
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildHelpTopicItem(
    BuildContext context, {
    required String title,
    required String subText,
    required List<List<dynamic>> icon,
  }) {
    final textTheme = getEnteTextTheme(context);
    return MenuItemWidgetNew(
      title: title,
      subText: subText,
      subTextStyle: textTheme.miniMuted,
      verticalPaddingWithSubText: 12,
      titleToSubTextSpacing: 2,
      leadingIconWidget: _buildIconWidget(context, icon),
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        await _openHelpPage(context, title: title);
      },
    );
  }

  Widget _buildIconWidget(BuildContext context, List<List<dynamic>> icon) {
    final colorScheme = getEnteColorScheme(context);
    return HugeIcon(
      icon: icon,
      color: colorScheme.menuItemIconStroke,
      size: 20,
    );
  }

  Future<void> _openHelpPage(
    BuildContext context, {
    required String title,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return WebPage(title, _helpUrl);
        },
      ),
    );
  }

  Future<void> _exportLogs(BuildContext context) async {
    try {
      final zipFilePath = await getZippedLogsFile(context);
      await exportLogs(context, zipFilePath);
    } catch (e, s) {
      _logger.severe("Failed to export logs", e, s);
      if (context.mounted) {
        showShortToast(
          context,
          AppLocalizations.of(context).somethingWentWrong,
        );
      }
    }
  }
}

class _SupportLink extends StatelessWidget {
  final String label;
  final Future<void> Function() onTap;

  const _SupportLink({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.small.copyWith(color: colorScheme.primary500),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_outlined,
              color: colorScheme.primary500,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
