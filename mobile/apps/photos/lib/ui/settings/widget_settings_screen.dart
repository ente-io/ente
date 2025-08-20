import 'package:flutter/material.dart';
import "package:flutter_svg/flutter_svg.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import "package:photos/ui/settings/ml/enable_ml_consent.dart";
import "package:photos/ui/settings/widgets/albums_widget_settings.dart";
import "package:photos/ui/settings/widgets/memories_widget_settings.dart";
import "package:photos/ui/settings/widgets/people_widget_settings.dart";
import "package:photos/utils/navigation_util.dart";

class WidgetSettingsScreen extends StatelessWidget {
  const WidgetSettingsScreen({super.key});

  void onPeopleTapped(BuildContext context) {
    final bool isMLEnabled = !flagService.hasGrantedMLConsent;
    if (isMLEnabled) {
      routeToPage(
        context,
        const EnableMachineLearningConsent(),
        forceCustomPageRoute: true,
      );
      return;
    }
    routeToPage(
      context,
      const PeopleWidgetSettings(),
    );
  }

  void onAlbumsTapped(BuildContext context) {
    routeToPage(
      context,
      const AlbumsWidgetSettings(),
    );
  }

  void onMemoriesTapped(BuildContext context) {
    routeToPage(
      context,
      const MemoriesWidgetSettings(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).widgets,
            ),
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          children: [
                            MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title: S.of(context).people,
                              ),
                              leadingIconWidget: SvgPicture.asset(
                                "assets/icons/people-widget-icon.svg",
                                colorFilter: ColorFilter.mode(
                                  colorScheme.textBase,
                                  BlendMode.srcIn,
                                ),
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              singleBorderRadius: 8,
                              trailingIcon: Icons.chevron_right_outlined,
                              onTap: () async => onPeopleTapped(context),
                            ),
                            const SizedBox(height: 8),
                            MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title: S.of(context).albums,
                              ),
                              leadingIconWidget: SvgPicture.asset(
                                "assets/icons/albums-widget-icon.svg",
                                colorFilter: ColorFilter.mode(
                                  colorScheme.textBase,
                                  BlendMode.srcIn,
                                ),
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              singleBorderRadius: 8,
                              trailingIcon: Icons.chevron_right_outlined,
                              onTap: () async => onAlbumsTapped(context),
                            ),
                            const SizedBox(height: 8),
                            MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title: S.of(context).memories,
                              ),
                              leadingIconWidget: SvgPicture.asset(
                                "assets/icons/memories-widget-icon.svg",
                                colorFilter: ColorFilter.mode(
                                  colorScheme.textBase,
                                  BlendMode.srcIn,
                                ),
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              singleBorderRadius: 8,
                              trailingIcon: Icons.chevron_right_outlined,
                              onTap: () async => onMemoriesTapped(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }
}
