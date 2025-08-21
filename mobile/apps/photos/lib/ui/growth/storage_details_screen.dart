import "dart:math";

import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/storage_bonus/storage_bonus.dart";
import "package:photos/models/user_details.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/utils/standalone/data.dart";

class StorageDetailsScreen extends StatefulWidget {
  final ReferralView referralView;
  final UserDetails userDetails;

  const StorageDetailsScreen(this.referralView, this.userDetails, {super.key});

  @override
  State<StorageDetailsScreen> createState() => _StorageDetailsScreenState();
}

class _StorageDetailsScreenState extends State<StorageDetailsScreen> {
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
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: AppLocalizations.of(context).claimFreeStorage,
            ),
            flexibleSpaceCaption: AppLocalizations.of(context).details,
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.of(context)
                    ..pop()
                    ..pop()
                    ..pop();
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (delegateBuildContext, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    // wrap the child inside a FutureBuilder to get the
                    // current state of the TextField
                    child: FutureBuilder<BonusDetails>(
                      future: storageBonusService.getBonusDetails(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 48.0),
                              child: EnteLoadingWidget(),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          debugPrint(snapshot.error.toString());
                          return Text(
                            AppLocalizations.of(context).oopsSomethingWentWrong,
                          );
                        } else {
                          final BonusDetails data = snapshot.data!;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BonusInfoSection(
                                  sectionName: AppLocalizations.of(context)
                                      .peopleUsingYourCode,
                                  leftValue: data.refUpgradeCount,
                                  leftUnitName:
                                      AppLocalizations.of(context).eligible,
                                  rightValue: data.refUpgradeCount >= 0
                                      ? data.refCount
                                      : null,
                                  rightUnitName:
                                      AppLocalizations.of(context).total,
                                  showUnit: data.refCount > 0,
                                ),
                                data.hasAppliedCode
                                    ? BonusInfoSection(
                                        sectionName:
                                            AppLocalizations.of(context)
                                                .codeUsedByYou,
                                        leftValue: 1,
                                        showUnit: false,
                                      )
                                    : const SizedBox.shrink(),
                                BonusInfoSection(
                                  sectionName: AppLocalizations.of(context)
                                      .freeStorageClaimed,
                                  leftValue: convertBytesToAbsoluteGBs(
                                    widget.referralView.claimedStorage,
                                  ),
                                  leftUnitName: "GB",
                                  rightValue: null,
                                ),
                                BonusInfoSection(
                                  sectionName: AppLocalizations.of(context)
                                      .freeStorageUsable,
                                  leftValue: convertBytesToAbsoluteGBs(
                                    min(
                                      widget.referralView.claimedStorage,
                                      widget.userDetails
                                          .getPlanPlusAddonStorage(),
                                    ),
                                  ),
                                  leftUnitName: "GB",
                                  rightValue: convertBytesToAbsoluteGBs(
                                    widget.userDetails
                                        .getPlanPlusAddonStorage(),
                                  ),
                                  rightUnitName: "GB",
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                Text(
                                  AppLocalizations.of(context)
                                      .usableReferralStorageInfo,
                                  style: textStyle.small
                                      .copyWith(color: colorScheme.textMuted),
                                ),
                              ],
                            ),
                          );
                        }
                      },
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

class BonusInfoSection extends StatelessWidget {
  final String sectionName;
  final bool showUnit;
  final String leftUnitName;
  final String rightUnitName;
  final int leftValue;
  final int? rightValue;

  const BonusInfoSection({
    super.key,
    required this.sectionName,
    required this.leftValue,
    this.leftUnitName = "GB",
    this.rightValue,
    this.rightUnitName = "GB",
    this.showUnit = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textStyle = getEnteTextTheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionName,
          style: textStyle.body.copyWith(
            color: colorScheme.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: leftValue.toString(),
                style: textStyle.h3,
              ),
              TextSpan(
                text: showUnit ? " $leftUnitName" : "",
                style: textStyle.large,
              ),
              TextSpan(
                text: (rightValue != null && rightValue! > 0)
                    ? " / ${rightValue.toString()}"
                    : "",
                style: textStyle.h3,
              ),
              TextSpan(
                text: showUnit && (rightValue != null && rightValue! > 0)
                    ? " $rightUnitName"
                    : "",
                style: textStyle.large,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
