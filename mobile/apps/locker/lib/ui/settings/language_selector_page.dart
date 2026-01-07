import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/components/separators.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/components/title_bar_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";

class LanguageSelectorPage extends StatelessWidget {
  final List<Locale> supportedLocales;
  final ValueChanged<Locale> onLocaleChanged;
  final Locale currentLocale;

  const LanguageSelectorPage(
    this.supportedLocales,
    this.onLocaleChanged,
    this.currentLocale, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: context.l10n.selectLanguage,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        child: _LanguageItemsWidget(
                          supportedLocales,
                          onLocaleChanged,
                          currentLocale,
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: 1,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.symmetric(vertical: 12)),
        ],
      ),
    );
  }
}

class _LanguageItemsWidget extends StatefulWidget {
  final List<Locale> supportedLocales;
  final ValueChanged<Locale> onLocaleChanged;
  final Locale currentLocale;

  const _LanguageItemsWidget(
    this.supportedLocales,
    this.onLocaleChanged,
    this.currentLocale,
  );

  @override
  State<_LanguageItemsWidget> createState() => _LanguageItemsWidgetState();
}

class _LanguageItemsWidgetState extends State<_LanguageItemsWidget> {
  late Locale currentLocale;

  @override
  void initState() {
    currentLocale = widget.currentLocale;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    for (Locale locale in widget.supportedLocales) {
      items.add(_menuItemForPicker(locale));
    }
    items = addSeparators(
      items,
      DividerWidget(
        dividerType: DividerType.menuNoIcon,
        bgColor: getEnteColorScheme(context).fillFaint,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'be':
        return 'Беларуская';
      case 'bg':
        return 'Български';
      case 'ca':
        return 'Català';
      case 'cs':
        return 'Čeština';
      case 'da':
        return 'Dansk';
      case 'de':
        return 'Deutsch';
      case 'el':
        return 'Ελληνικά';
      case 'en':
        return 'English';
      case 'es':
        switch (locale.countryCode) {
          case 'ES':
            return 'Español (España)';
          default:
            return 'Español';
        }
      case 'et':
        return 'Eesti';
      case 'fa':
        return 'فارسی';
      case 'fi':
        return 'Suomi';
      case 'fr':
        return 'Français';
      case 'gu':
        return 'ગુજરાતી';
      case 'he':
        return 'עברית';
      case 'hi':
        return 'हिन्दी';
      case 'hu':
        return 'Magyar';
      case 'id':
        return 'Bahasa Indonesia';
      case 'it':
        return 'Italiano';
      case 'ja':
        return '日本語';
      case 'ka':
        return 'ქართული';
      case 'km':
        return 'ភាសាខ្មែរ';
      case 'ko':
        return '한국어';
      case 'lt':
        return 'Lietuvių';
      case 'lv':
        return 'Latviešu';
      case 'ml':
        return 'മലയാളം';
      case 'nl':
        return 'Nederlands';
      case 'no':
        return 'Norsk';
      case 'pl':
        return 'Polski';
      case 'pt':
        switch (locale.countryCode) {
          case 'BR':
            return 'Português (Brasil)';
          default:
            return 'Português';
        }
      case 'ro':
        return 'Română';
      case 'ru':
        return 'Русский';
      case 'sk':
        return 'Slovenčina';
      case 'sl':
        return 'Slovenščina';
      case 'sr':
        return 'Српски';
      case 'sv':
        return 'Svenska';
      case 'ti':
        return 'ትግርኛ';
      case 'tr':
        return 'Türkçe';
      case 'uk':
        return 'Українська';
      case 'vi':
        return 'Tiếng Việt';
      case 'zh':
        if (locale.countryCode == 'TW') {
          return '中文 (台灣)';
        } else if (locale.countryCode == 'HK') {
          return '中文 (香港)';
        } else if (locale.countryCode == 'CN') {
          return '中文 (中国)';
        }
        switch (locale.scriptCode) {
          case 'Hans':
            return '中文 (简体)';
          case 'Hant':
            return '中文 (繁體)';
          default:
            return '中文';
        }
      default:
        return locale.languageCode;
    }
  }

  Widget _menuItemForPicker(Locale locale) {
    return MenuItemWidget(
      key: ValueKey(locale.toString()),
      menuItemColor: getEnteColorScheme(context).fillFaint,
      captionedTextWidget: CaptionedTextWidget(
        title: _getLanguageName(locale) + (kDebugMode ? ' ($locale)' : ''),
      ),
      trailingIcon: currentLocale == locale ? Icons.check : null,
      alignCaptionedTextToLeft: true,
      isTopBorderRadiusRemoved: true,
      isBottomBorderRadiusRemoved: true,
      showOnlyLoadingState: true,
      onTap: () async {
        widget.onLocaleChanged(locale);
        currentLocale = locale;
        setState(() {});
      },
    );
  }
}
