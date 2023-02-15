import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:photos/models/api/storage_bonus/storage_bonus.dart";
import "package:photos/models/user_details.dart";
import "package:photos/services/storage_bonus_service.dart";
import "package:photos/services/user_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/common/web_page.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/icon_button_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/growth/apply_code_screen.dart";
import "package:photos/ui/growth/storage_details_screen.dart";
import "package:photos/utils/data_util.dart";
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
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: const TitleBarTitleWidget(
              title: "Claim free storage",
            ),
            flexibleSpaceCaption: "Invite your friends",
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: FutureBuilder<ReferralView>(
                    future: StorageBonusService.instance
                        .getGateway()
                        .getReferralView(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ReferralWidget(
                          snapshot.data!,
                          UserService.instance.getCachedUserDetails()!,
                        );
                      } else {
                        return const EnteLoadingWidget();
                      }
                    },
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

class ReferralWidget extends StatelessWidget {
  final ReferralView referralView;
  final UserDetails userDetails;

  const ReferralWidget(this.referralView, this.userDetails, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textStyle = getEnteTextTheme(context);
    final bool isReferralEnabled = referralView.planInfo.isEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Container with 8 border radius and red color
        isReferralEnabled
            ? Container(
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
                                  referralView.code,
                                  style: textStyle.bodyBold.copyWith(
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
                      Text(
                        "3. Both of you get ${referralView.planInfo.storageInGB} "
                        "GB* free",
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.strokeMuted,
                      ),
                      const SizedBox(height: 12),
                      Text("Referrals are currently paused",
                          style: textStyle.small
                              .copyWith(color: colorScheme.textFaint)),
                    ],
                  ),
                ),
              ),
        const SizedBox(height: 4),
        isReferralEnabled
            ? Text(
                "* You can at max double your storage",
                style: textStyle.mini.copyWith(
                  color: colorScheme.textMuted,
                ),
                textAlign: TextAlign.left,
              )
            : const SizedBox.shrink(),
        const SizedBox(height: 24),
        referralView.enableApplyCode
            ? MenuItemWidget(
                captionedTextWidget: const CaptionedTextWidget(
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
                    context,
                    const ApplyCodeScreen(),
                  );
                },
              )
            : const SizedBox.shrink(),
        referralView.enableApplyCode
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
          isTopBorderRadiusRemoved: referralView.enableApplyCode,
          alignCaptionedTextToLeft: true,
          onTap: () async {
            routeToPage(context, const WebPage("FAQ", "https://ente.io/faq"));
          },
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 6.0,
          ),
          child: Text(
            "${referralView.isFamilyMember ? 'Your family has' : 'You have'} claimed "
            "${convertBytesToAbsoluteGBs(referralView.claimedStorage)} GB so far",
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
            routeToPage(
              context,
              StorageDetailsScreen(referralView, userDetails),
            );
          },
        ),
      ],
    );
  }
}
