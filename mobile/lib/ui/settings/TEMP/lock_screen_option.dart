import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/settings/TEMP/lock_screen_option_password.dart";
import "package:photos/ui/settings/TEMP/lock_screen_option_pin.dart";

class LockScreenOption extends StatelessWidget {
  const LockScreenOption({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).lockscreen,
            ),
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
                                title: S.of(context).noDeviceLimit,
                              ),
                              alignCaptionedTextToLeft: true,
                              isTopBorderRadiusRemoved: false,
                              isBottomBorderRadiusRemoved: true,
                              menuItemColor: colorScheme.fillFaint,
                              trailingIconIsMuted: true,
                              trailingIcon: Icons.chevron_right_outlined,
                            ),
                            DividerWidget(
                              dividerType: DividerType.menuNoIcon,
                              bgColor: colorScheme.fillFaint,
                            ),
                            MenuItemWidget(
                              captionedTextWidget: const CaptionedTextWidget(
                                title: 'Device Lock',
                              ),
                              alignCaptionedTextToLeft: true,
                              isTopBorderRadiusRemoved: true,
                              isBottomBorderRadiusRemoved: true,
                              menuItemColor: colorScheme.fillFaint,
                              trailingIconIsMuted: true,
                              trailingIcon: Icons.chevron_right_outlined,
                            ),
                            DividerWidget(
                              dividerType: DividerType.menuNoIcon,
                              bgColor: colorScheme.fillFaint,
                            ),
                            MenuItemWidget(
                              captionedTextWidget: const CaptionedTextWidget(
                                title: 'PIN lock',
                              ),
                              alignCaptionedTextToLeft: true,
                              isTopBorderRadiusRemoved: true,
                              isBottomBorderRadiusRemoved: true,
                              menuItemColor: colorScheme.fillFaint,
                              trailingIconIsMuted: true,
                              trailingIcon: Icons.chevron_right_outlined,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return const LockScreenOptionPin();
                                  },
                                ),
                              ),
                            ),
                            DividerWidget(
                              dividerType: DividerType.menuNoIcon,
                              bgColor: colorScheme.fillFaint,
                            ),
                            MenuItemWidget(
                              captionedTextWidget: const CaptionedTextWidget(
                                title: 'Password lock',
                              ),
                              alignCaptionedTextToLeft: true,
                              isTopBorderRadiusRemoved: true,
                              isBottomBorderRadiusRemoved: false,
                              menuItemColor: colorScheme.fillFaint,
                              trailingIconIsMuted: true,
                              trailingIcon: Icons.chevron_right_outlined,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return const LockScreenOptionPassword();
                                  },
                                ),
                              ),
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
