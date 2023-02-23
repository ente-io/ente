import "package:flutter/material.dart";
import "package:photos/models/api/storage_bonus/storage_bonus.dart";
import "package:photos/models/user_details.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/icon_button_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/growth/referral_code_widget.dart";
import "package:photos/ui/growth/storage_details_screen.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/share_util.dart";

class CodeSuccessScreen extends StatelessWidget {
  final ReferralView referralView;
  final UserDetails userDetails;

  const CodeSuccessScreen(this.referralView, this.userDetails, {super.key});

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
              title: "Code applied",
            ),
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (delegateBuildContext, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "${referralView.planInfo.storageInGB} GB",
                          style: textStyle.h2Bold,
                        ),
                        Text(
                          "Claimed",
                          style: textStyle.body
                              .copyWith(color: colorScheme.textMuted),
                        ),
                        const SizedBox(height: 32),
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
                        const SizedBox(height: 32),
                        InkWell(
                          onTap: () {
                            shareText(
                              "ente referral code: ${referralView.code} \n\nApply it in Settings → General → Referrals to get ${referralView.planInfo.storageInGB} GB free after you signup for a paid plan\n\nhttps://ente.io",
                            );
                          },
                          child: Container(
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Claim more!",
                                    style: textStyle.body,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${referralView.planInfo.storageInGB} GB each time someone signs up for a paid plan and applies your code",
                                    style: textStyle.small
                                        .copyWith(color: colorScheme.textMuted),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ReferralCodeWidget(referralView.code),
                                  const SizedBox(height: 16),
                                  Text(
                                    "They also get ${referralView.planInfo.storageInGB} GB",
                                    style: textStyle.small
                                        .copyWith(color: colorScheme.textMuted),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
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
