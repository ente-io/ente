import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/utils/separators_util.dart";

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
    bool foundMatch = false;
    for (Locale locale in widget.supportedLocales) {
      if (currentLocale == locale) {
        foundMatch = true;
      }
      items.add(
        _menuItemForPicker(locale),
      );
    }
    if (!foundMatch && kDebugMode) {
      items.insert(
        0,
        Text("(i) Locale : ${currentLocale.toString()}"),
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
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'ja':
        return '日本語';
      case 'nl':
        return 'Nederlands';
      case 'no':
        return 'Norsk';
      case 'pl':
        return 'Polski';
      case 'pt':
        if (locale.countryCode == 'BR') {
          return 'Português (Brasil)';
        } else if (locale.countryCode == 'PT') {
          return 'Português (Portugal)';
        }
        return 'Português';
      case 'ro':
        return 'Română';
      case 'ru':
        return 'Русский';
      case 'tr':
        return 'Türkçe';
      case 'fi':
        return 'Suomi';
      case 'zh':
        return '中文';
      case 'zh-CN':
        return '中文';
      case 'ko':
        return '한국어';
      case 'ar':
        return 'العربية';
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
