import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/app.dart";
import "package:locker/core/locale.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/settings/language_selector_page.dart";
import "package:locker/ui/settings/widgets/settings_widget.dart";

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

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
              TitleBarTitleWidget(title: l10n.general),
              const SizedBox(height: 24),
              SettingsItem(
                title: l10n.selectLanguage,
                onTap: () => _onLanguageTapped(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onLanguageTapped(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LanguageSelectorPage(
          appSupportedLocales,
          (locale) {
            App.setLocale(context, locale);
            // ignore: unawaited_futures
            setLocale(locale);
          },
          currentLocale,
        ),
      ),
    );
  }
}
