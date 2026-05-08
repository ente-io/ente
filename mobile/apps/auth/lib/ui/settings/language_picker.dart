import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/divider_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/components/separators.dart';
import 'package:ente_auth/ui/components/title_bar_title_widget.dart';
import 'package:ente_auth/ui/components/title_bar_widget.dart';
import 'package:ente_pure_utils/ente_pure_utils.dart';
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
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
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
      items.add(_menuItemForPicker(locale));
    }
    items = addSeparators(
      items,
      DividerWidget(
        dividerType: DividerType.menuNoIcon,
        bgColor: getEnteColorScheme(context).fillFaint,
      ),
    );
    return Column(mainAxisSize: MainAxisSize.min, children: items);
  }

  Widget _menuItemForPicker(Locale locale) {
    return MenuItemWidget(
      key: ValueKey(locale.toString()),
      menuItemColor: getEnteColorScheme(context).fillFaint,
      captionedTextWidget: CaptionedTextWidget(
        title: getLocaleDisplayName(locale) + (kDebugMode ? ' ($locale)' : ''),
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
