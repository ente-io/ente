import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/storage_bonus/storage_bonus.dart";
import "package:photos/models/user_details.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/components/captioned_text_widget.dart";
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
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: AppLocalizations.of(context).codeAppliedPageTitle,
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
                        Icon(
                          Icons.check,
                          color: colorScheme.primary500,
                          size: 96,
                        )
                            .animate()
                            .scaleXY(
                              begin: 0.5,
                              end: 1,
                              duration: 750.ms,
                              curve: Curves.easeInOutCubic,
                              delay: 250.ms,
                            )
                            .fadeIn(
                              duration: 500.ms,
                              curve: Curves.easeInOutCubic,
                            ),
                        Text(
                          AppLocalizations.of(context).storageInGB(
                            storageAmountInGB:
                                referralView.planInfo.storageInGB,
                          ),
                          style: textStyle.h2Bold,
                        ),
                        Text(
                          AppLocalizations.of(context).claimed,
                          style: textStyle.bodyMuted,
                        ),
                        const SizedBox(height: 32),
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
                        const SizedBox(height: 32),
                        InkWell(
                          onTap: () {
                            shareText(
                              AppLocalizations.of(context)
                                  .shareTextReferralCode(
                                referralCode: referralView.code,
                                referralStorageInGB:
                                    referralView.planInfo.storageInGB,
                              ),
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
                                    AppLocalizations.of(context).claimMore,
                                    style: textStyle.body,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)
                                        .freeStorageOnReferralSuccess(
                                      storageAmountInGB:
                                          referralView.planInfo.storageInGB,
                                    ),
                                    style: textStyle.smallMuted,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ReferralCodeWidget(referralView.code),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context).theyAlsoGetXGb(
                                      storageAmountInGB:
                                          referralView.planInfo.storageInGB,
                                    ),
                                    style: textStyle.smallMuted,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
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
