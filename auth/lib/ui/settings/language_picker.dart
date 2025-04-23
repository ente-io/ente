import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/divider_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/components/separators.dart';
import 'package:ente_auth/ui/components/title_bar_title_widget.dart';
import 'package:ente_auth/ui/components/title_bar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints.tightFor(width: 450),
          child: CustomScrollView(
            primary: false,
            slivers: <Widget>[
              TitleBarWidget(
                flexibleSpaceTitle: TitleBarTitleWidget(
                  title: l10n.selectLanguage,
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
                            child: ItemsWidget(
                              supportedLocales,
                              onLocaleChanged,
                              currentLocale,
                            ),
                          ),
                          // MenuSectionDescriptionWidget(
                          //   content: context.l10n.maxDeviceLimitSpikeHandling(50),
                          // )
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
        ),
      ),
    );
  }
}

class ItemsWidget extends StatefulWidget {
  final List<Locale> supportedLocales;
  final ValueChanged<Locale> onLocaleChanged;
  final Locale currentLocale;

  const ItemsWidget(
    this.supportedLocales,
    this.onLocaleChanged,
    this.currentLocale, {
    super.key,
  });

  @override
  State<ItemsWidget> createState() => _ItemsWidgetState();
}

class _ItemsWidgetState extends State<ItemsWidget> {
  late Locale currentLocale;
  List<Widget> items = [];

  @override
  void initState() {
    currentLocale = widget.currentLocale;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    items.clear();
    for (Locale locale in widget.supportedLocales) {
      items.add(
        _menuItemForPicker(locale),
      );
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
      case 'ca':
        return 'Català';
      case 'cs':
        return 'Čeština';
      case 'en':
        return 'English';
      case 'bg':
        return 'Български';
      case 'el':
        return 'Ελληνικά';
      case 'es':
        switch (locale.countryCode) {
          case 'ES':
            return 'Español (España)';
          default:
            return 'Español';
        }
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'he':
        return 'עברית';
      case 'hu':
        return 'Magyar';
      case 'id':
        return 'Bahasa Indonesia';
      case 'it':
        return 'Italiano';
      case 'lt':
        return 'Lietuvių';
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
      case 'sl':
        return 'Slovenščina';
      case 'sk':
        return 'Slovenčina';
      case 'tr':
        return 'Türkçe';
      case 'uk':
        return 'Українська';
      case 'vi':
        return 'Tiếng Việt';
      case 'fi':
        return 'Suomi';
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
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'fa':
        return 'فارسی';
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
