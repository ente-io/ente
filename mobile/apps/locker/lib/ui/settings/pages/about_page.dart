import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_utils/platform_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/settings/widgets/settings_widget.dart";
import "package:url_launcher/url_launcher.dart";

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
              TitleBarTitleWidget(title: l10n.about),
              const SizedBox(height: 24),
              SettingsItem(
                title: l10n.weAreOpenSource,
                onTap: () => _onOpenSourceTapped(),
              ),
              const SizedBox(height: 8),
              SettingsItem(
                title: l10n.privacy,
                onTap: () => _onPrivacyTapped(context),
              ),
              const SizedBox(height: 8),
              SettingsItem(
                title: l10n.termsOfServicesTitle,
                onTap: () => _onTermsTapped(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onOpenSourceTapped() {
    // ignore: unawaited_futures
    launchUrl(Uri.parse("https://github.com/ente-io/ente"));
  }

  Future<void> _onPrivacyTapped(BuildContext context) async {
    final l10n = context.l10n;
    await PlatformUtil.openWebView(
      context,
      l10n.privacy,
      "https://ente.io/privacy",
    );
  }

  Future<void> _onTermsTapped(BuildContext context) async {
    final l10n = context.l10n;
    await PlatformUtil.openWebView(
      context,
      l10n.termsOfServicesTitle,
      "https://ente.io/terms",
    );
  }
}
