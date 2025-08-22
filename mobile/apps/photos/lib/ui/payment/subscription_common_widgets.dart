import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/api/billing/subscription.dart';
import "package:photos/models/api/storage_bonus/bonus.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import 'package:photos/ui/payment/billing_questions_widget.dart';
import 'package:photos/utils/standalone/data.dart';

class SubscriptionHeaderWidget extends StatefulWidget {
  final bool? isOnboarding;
  final int? currentUsage;

  const SubscriptionHeaderWidget({
    super.key,
    this.isOnboarding,
    this.currentUsage,
  });

  @override
  State<StatefulWidget> createState() {
    return _SubscriptionHeaderWidgetState();
  }
}

class _SubscriptionHeaderWidgetState extends State<SubscriptionHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    if (widget.isOnboarding!) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          AppLocalizations.of(context).enteSubscriptionPitch,
          style: getEnteTextTheme(context).smallFaint,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: AppLocalizations.of(context).currentUsageIs,
                style: textTheme.bodyFaint,
              ),
              TextSpan(
                text: formatBytes(widget.currentUsage!),
                style: textTheme.body.copyWith(
                  color: colorScheme.primary700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class ValidityWidget extends StatelessWidget {
  final Subscription? currentSubscription;
  final BonusData? bonusData;

  const ValidityWidget({super.key, this.currentSubscription, this.bonusData});

  @override
  Widget build(BuildContext context) {
    final List<Bonus> addOnBonus = bonusData?.getAddOnBonuses() ?? <Bonus>[];
    if (currentSubscription == null ||
        (currentSubscription!.isFreePlan() && addOnBonus.isEmpty)) {
      return const SizedBox(
        height: 56,
      );
    }
    final bool isFreeTrialSub = currentSubscription!.productID == freeProductID;
    bool hideSubValidityView = false;
    if (isFreeTrialSub && addOnBonus.isNotEmpty) {
      hideSubValidityView = true;
    }
    if (!currentSubscription!.isValid()) {
      hideSubValidityView = true;
    }
    final endDate =
        DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(
      DateTime.fromMicrosecondsSinceEpoch(currentSubscription!.expiryTime),
    );

    var message = AppLocalizations.of(context).renewsOn(endDate: endDate);
    if (currentSubscription!.attributes?.isCancelled ?? false) {
      message =
          AppLocalizations.of(context).subWillBeCancelledOn(endDate: endDate);
      if (addOnBonus.isNotEmpty) {
        hideSubValidityView = true;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          if (!hideSubValidityView)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message,
                style: getEnteTextTheme(context).body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          if (addOnBonus.isNotEmpty)
            ...addOnBonus.map((bonus) => AddOnBonusValidity(bonus)),
        ],
      ),
    );
  }
}

class AddOnBonusValidity extends StatelessWidget {
  final Bonus bonus;

  const AddOnBonusValidity(this.bonus, {super.key});

  @override
  Widget build(BuildContext context) {
    final endDate =
        DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(
      DateTime.fromMicrosecondsSinceEpoch(bonus.validTill),
    );
    final String storage = convertBytesToReadableFormat(bonus.storage);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        AppLocalizations.of(context)
            .addOnValidTill(storageAmount: storage, endDate: endDate),
        style: getEnteTextTheme(context).smallFaint,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SubFaqWidget extends StatelessWidget {
  final bool isOnboarding;

  const SubFaqWidget({super.key, this.isOnboarding = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      child: MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: AppLocalizations.of(context).faqs,
        ),
        menuItemColor: colorScheme.fillFaint,
        trailingWidget: Icon(
          Icons.chevron_right_outlined,
          color: colorScheme.strokeBase,
        ),
        singleBorderRadius: 4,
        alignCaptionedTextToLeft: true,
        onTap: () async {
          // ignore: unawaited_futures
          showModalBottomSheet<void>(
            backgroundColor: Theme.of(context).colorScheme.bgColorForQuestions,
            barrierColor: Colors.black87,
            context: context,
            builder: (context) {
              return const SafeArea(
                child: BillingQuestionsWidget(),
              );
            },
          );
        },
      ),
    );
  }
}

class SubscriptionToggle extends StatefulWidget {
  final Function(bool) onToggle;
  const SubscriptionToggle({required this.onToggle, super.key});

  @override
  State<SubscriptionToggle> createState() => _SubscriptionToggleState();
}

class _SubscriptionToggleState extends State<SubscriptionToggle> {
  bool _isYearly = true;
  @override
  Widget build(BuildContext context) {
    const borderPadding = 2.5;
    const spaceBetweenButtons = 4.0;
    final textTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: LayoutBuilder(
        builder: (context, constrains) {
          final widthOfButton = (constrains.maxWidth -
                  (borderPadding * 2) -
                  spaceBetweenButtons) /
              2;
          return Container(
            decoration: BoxDecoration(
              color: getEnteColorScheme(context).fillBaseGrey,
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: borderPadding,
              horizontal: borderPadding,
            ),
            width: double.infinity,
            child: Stack(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setIsYearly(false);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        width: widthOfButton,
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).monthly,
                            style: textTheme.bodyFaint,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: spaceBetweenButtons),
                    GestureDetector(
                      onTap: () {
                        setIsYearly(true);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        width: widthOfButton,
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).yearly,
                            style: textTheme.bodyFaint,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutQuart,
                  left: _isYearly ? widthOfButton + spaceBetweenButtons : 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    width: widthOfButton,
                    decoration: BoxDecoration(
                      color: getEnteColorScheme(context).backgroundBase,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeInOutExpo,
                      switchOutCurve: Curves.easeInOutExpo,
                      child: Text(
                        key: ValueKey(_isYearly),
                        _isYearly
                            ? AppLocalizations.of(context).yearly
                            : AppLocalizations.of(context).monthly,
                        style: textTheme.body,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  setIsYearly(bool isYearly) {
    setState(() {
      _isYearly = isYearly;
    });
    widget.onToggle(isYearly);
  }
}
