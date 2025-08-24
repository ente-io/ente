import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/storage_bonus/storage_bonus.dart";
import "package:photos/models/user_details.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/common/web_page.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/growth/apply_code_screen.dart";
import "package:photos/ui/growth/referral_code_widget.dart";
import "package:photos/ui/growth/storage_details_screen.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/share_util.dart";
import "package:photos/utils/standalone/data.dart";
import "package:tuple/tuple.dart";

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  bool canApplyCode = true;

  void _safeUIUpdate() {
    if (mounted) {
      setState(() => {});
    }
  }

  Future<Tuple2<ReferralView, UserDetails>> _fetchData() async {
    UserDetails? cachedUserDetails =
        UserService.instance.getCachedUserDetails();
    cachedUserDetails ??=
        await UserService.instance.getUserDetailsV2(memoryCount: false);
    final referralView = await storageBonusService.getReferralView();
    return Tuple2(referralView, cachedUserDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: AppLocalizations.of(context).claimFreeStorage,
            ),
            flexibleSpaceCaption:
                AppLocalizations.of(context).inviteYourFriends,
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
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
                  child: FutureBuilder<Tuple2<ReferralView, UserDetails>>(
                    future: _fetchData(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ReferralWidget(
                          referralView: snapshot.data!.item1,
                          userDetails: snapshot.data!.item2,
                          notifyParent: _safeUIUpdate,
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              AppLocalizations.of(context)
                                  .failedToFetchReferralDetails,
                            ),
                          ),
                        );
                      }
                      {
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
  final Function notifyParent;

  const ReferralWidget({
    required this.referralView,
    required this.userDetails,
    required this.notifyParent,
    super.key,
  });

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
            ? InkWell(
                onTap: () {
                  shareText(
                    AppLocalizations.of(context).shareTextReferralCode(
                      referralCode: referralView.code,
                      referralStorageInGB: referralView.planInfo.storageInGB,
                    ),
                  );
                },
                child: Stack(
                  children: [
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
                            Text(
                              AppLocalizations.of(context).referralStep1,
                            ),
                            const SizedBox(height: 12),
                            ReferralCodeWidget(
                              referralView.code,
                              shouldShowEdit: true,
                              userDetails: userDetails,
                              notifyParent: notifyParent,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context).referralStep2,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context).referralStep3(
                                storageInGB: referralView.planInfo.storageInGB,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Icon(
                        Icons.adaptive.share,
                        color: colorScheme.blurStrokePressed,
                      ),
                    ),
                  ],
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
                      Text(
                        AppLocalizations.of(context)
                            .referralsAreCurrentlyPaused,
                        style: textStyle.small
                            .copyWith(color: colorScheme.textFaint),
                      ),
                    ],
                  ),
                ),
              ),
        const SizedBox(height: 4),
        isReferralEnabled
            ? Text(
                AppLocalizations.of(context).youCanAtMaxDoubleYourStorage,
                style: textStyle.mini.copyWith(
                  color: colorScheme.textMuted,
                ),
                textAlign: TextAlign.left,
              )
            : const SizedBox.shrink(),
        const SizedBox(height: 24),
        referralView.enableApplyCode
            ? MenuItemWidget(
                captionedTextWidget: CaptionedTextWidget(
                  title: AppLocalizations.of(context).applyCodeTitle,
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
                  await routeToPage(
                    context,
                    ApplyCodeScreen(referralView, userDetails),
                  );
                  notifyParent();
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
          captionedTextWidget: CaptionedTextWidget(
            title: AppLocalizations.of(context).faq,
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
            // ignore: unawaited_futures
            routeToPage(
              context,
              WebPage(
                AppLocalizations.of(context).faq,
                "https://help.ente.io/photos/features/referral-program/",
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 6.0,
          ),
          child: Text(
            AppLocalizations.of(context).claimedStorageSoFar(
              isFamilyMember:
                  referralView.isFamilyMember.toString().toLowerCase(),
              storageAmountInGb:
                  convertBytesToAbsoluteGBs(referralView.claimedStorage),
            ),
            style: textStyle.small.copyWith(
              color: colorScheme.textMuted,
            ),
          ),
        ),
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: AppLocalizations.of(context).details,
          ),
          menuItemColor: colorScheme.fillFaint,
          trailingWidget: Icon(
            Icons.chevron_right_outlined,
            color: colorScheme.strokeBase,
          ),
          singleBorderRadius: 8,
          alignCaptionedTextToLeft: true,
          onTap: () async {
            // ignore: unawaited_futures
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
