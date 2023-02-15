import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/icon_button_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/growth/apply_code_screen.dart";
import "package:photos/ui/tools/debug/app_storage_viewer.dart";
import "package:photos/utils/navigation_util.dart";

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  bool canApplyCode = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textStyle = getEnteTextTheme(context);
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: const TitleBarTitleWidget(
              title: "Claim free storage",
            ),
            flexibleSpaceCaption: "Invite friends to claim free storage",
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
              (delegateBuildContext, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Container with 8 border radius and red color
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colorScheme.strokeFaint,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "1. Give this code to your "
                                      "friends",
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: DottedBorder(
                                        color: colorScheme.strokeMuted,
                                        //color of dotted/dash line
                                        strokeWidth: 1,
                                        //thickness of dash/dots
                                        dashPattern: const [6, 6],
                                        radius: const Radius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 26.0,
                                            top: 14,
                                            right: 12,
                                            bottom: 14,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "AX17D9EB",
                                                style:
                                                    textStyle.bodyBold.copyWith(
                                                  color: colorScheme.primary700,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(
                                                Icons.adaptive.share,
                                                size: 22,
                                                color: colorScheme.strokeMuted,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "2. They sign up for a paid plan",
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "3. Both of you get 10 GB* free",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "* You can at max double your storage",
                              style: textStyle.mini.copyWith(
                                color: colorScheme.textMuted,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 24),
                            canApplyCode
                                ? MenuItemWidget(
                                    captionedTextWidget:
                                        const CaptionedTextWidget(
                                      title: "Apply code",
                                    ),
                                    menuItemColor: colorScheme.fillFaint,
                                    trailingWidget: Icon(
                                      Icons.chevron_right_outlined,
                                      color: colorScheme.strokeBase,
                                    ),
                                    singleBorderRadius: 8,
                                    alignCaptionedTextToLeft: true,
                                    isBottomBorderRadiusRemoved: true,
                                    onTap: () async {
                                      routeToPage(
                                          context, const ApplyCodeScreen());
                                    },
                                  )
                                : const SizedBox.shrink(),
                            canApplyCode
                                ? DividerWidget(
                                    dividerType: DividerType.menu,
                                    bgColor: colorScheme.fillFaint,
                                  )
                                : const SizedBox.shrink(),
                            MenuItemWidget(
                              captionedTextWidget: const CaptionedTextWidget(
                                title: "FAQ",
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              trailingWidget: Icon(
                                Icons.chevron_right_outlined,
                                color: colorScheme.strokeBase,
                              ),
                              singleBorderRadius: 8,
                              isTopBorderRadiusRemoved: canApplyCode,
                              alignCaptionedTextToLeft: true,
                              onTap: () async {
                                routeToPage(context, const AppStorageViewer());
                              },
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 6.0,
                              ),
                              child: Text(
                                "You have claimed 0 GB so far",
                                style: textStyle.small.copyWith(
                                  color: colorScheme.textMuted,
                                ),
                              ),
                            ),
                            MenuItemWidget(
                              captionedTextWidget: const CaptionedTextWidget(
                                title: "Details",
                              ),
                              menuItemColor: colorScheme.fillFaint,
                              trailingWidget: Icon(
                                Icons.chevron_right_outlined,
                                color: colorScheme.strokeBase,
                              ),
                              singleBorderRadius: 8,
                              alignCaptionedTextToLeft: true,
                              onTap: () async {
                                routeToPage(context, const AppStorageViewer());
                              },
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
