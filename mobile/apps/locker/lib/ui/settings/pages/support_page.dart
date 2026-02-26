import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_utils/email_util.dart";
import "package:ente_utils/platform_util.dart";
import "package:flutter/material.dart";
import "package:locker/core/constants.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/settings/widgets/settings_widget.dart";
import "package:url_launcher/url_launcher_string.dart";

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = getEnteColorScheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitleBarTitleWidget(title: l10n.support),
              const SizedBox(height: 24),
              SettingsItem(
                title: l10n.contactSupport,
                onTap: () => _onContactSupportTapped(context),
              ),
              const SizedBox(height: 8),
              SettingsItem(
                title: l10n.help,
                onTap: () => _onHelpTapped(context),
              ),
              const SizedBox(height: 8),
              SettingsItem(
                title: l10n.suggestFeatures,
                onTap: () => _onSuggestFeaturesTapped(),
              ),
              const SizedBox(height: 8),
              SettingsItem(
                title: l10n.reportABug,
                onTap: () => _onReportBugTapped(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onContactSupportTapped(BuildContext context) async {
    await sendEmail(context, to: supportEmail);
  }

  Future<void> _onHelpTapped(BuildContext context) async {
    final l10n = context.l10n;
    await PlatformUtil.openWebView(
      context,
      l10n.help,
      "https://ente.io/help",
    );
  }

  void _onSuggestFeaturesTapped() {
    // ignore: unawaited_futures
    launchUrlString(
      githubDiscussionsUrl,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _onReportBugTapped(BuildContext context) async {
    final l10n = context.l10n;
    await sendLogs(
      context,
      "support@ente.io",
      dialogBody: l10n.logsDialogBodyLocker,
    );
  }
}
