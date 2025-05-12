import 'package:flutter/material.dart';
import "package:flutter_svg/flutter_svg.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import "package:photos/ui/components/toggle_switch_widget.dart";

class MemoriesWidgetSettings extends StatelessWidget {
  const MemoriesWidgetSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).memories,
            ),
            expandedHeight: 120,
            flexibleSpaceCaption: S.of(context).memoriesWidgetDesc,
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          if (1 != 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.5 - 300,
                    ),
                    Image.asset(
                      "assets/memories-widget-static.png",
                      height: 160,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Add a memories widget to your homescreen and come back here to customize",
                      style: textTheme.largeFaint,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 18),
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: S.of(context).pastYearsMemories,
                          ),
                          leadingIconWidget: SvgPicture.asset(
                            "assets/icons/past-year-memory-icon.svg",
                          ),
                          menuItemColor: colorScheme.fillFaint,
                          trailingWidget: ToggleSwitchWidget(
                            value: () => true,
                            onChanged: () async {},
                          ),
                          singleBorderRadius: 8,
                          isGestureDetectorDisabled: true,
                        ),
                        const SizedBox(height: 4),
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: S.of(context).smartMemories,
                          ),
                          leadingIconWidget: SvgPicture.asset(
                            "assets/icons/smart-memory-icon.svg",
                          ),
                          menuItemColor: colorScheme.fillFaint,
                          trailingWidget: ToggleSwitchWidget(
                            value: () => true,
                            onChanged: () async {},
                          ),
                          singleBorderRadius: 8,
                          isGestureDetectorDisabled: true,
                        ),
                      ],
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
