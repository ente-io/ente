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
      case 'cs':
        return 'Čeština';
      case 'de':
        return 'Deutsch';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'it':
        return 'Italiano';
      case 'ja':
        return '日本語';
      case 'nl':
        return 'Nederlands';
      case 'pl':
        return 'Polski';
      case 'pt':
        return 'Português';
      case 'ro':
        return 'Română';
      case 'ru':
        return 'Русский';
      case 'tr':
        return 'Türkçe';
      case 'uk':
        return 'Українська';
      case 'vi':
        return 'Tiếng Việt';
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
