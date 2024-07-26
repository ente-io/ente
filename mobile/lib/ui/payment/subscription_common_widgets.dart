import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/storage_bonus/bonus.dart";
import 'package:photos/models/subscription.dart';
import "package:photos/services/update_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import 'package:photos/ui/payment/billing_questions_widget.dart';
import 'package:photos/utils/data_util.dart';

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
          S.of(context).enteSubscriptionPitch,
          style: getEnteTextTheme(context).smallFaint,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: S.of(context).currentUsageIs,
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

  const ValidityWidget({Key? key, this.currentSubscription, this.bonusData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentSubscription == null) {
      return const SizedBox.shrink();
    }
    final List<Bonus> addOnBonus = bonusData?.getAddOnBonuses() ?? <Bonus>[];
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

    var message = S.of(context).renewsOn(endDate);
    if (isFreeTrialSub) {
      message = UpdateService.instance.isPlayStoreFlavor()
          ? S.of(context).playStoreFreeTrialValidTill(endDate)
          : S.of(context).freeTrialValidTill(endDate);
    } else if (currentSubscription!.attributes?.isCancelled ?? false) {
      message = S.of(context).subWillBeCancelledOn(endDate);
      if (addOnBonus.isNotEmpty) {
        hideSubValidityView = true;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Column(
        children: [
          if (!hideSubValidityView)
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          if (addOnBonus.isNotEmpty)
            ...addOnBonus.map((bonus) => AddOnBonusValidity(bonus)).toList(),
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
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        S.of(context).addOnValidTill(storage, endDate),
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SubFaqWidget extends StatelessWidget {
  final bool isOnboarding;

  const SubFaqWidget({Key? key, this.isOnboarding = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 40, 16, isOnboarding ? 40 : 4),
      child: MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: S.of(context).faqs,
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
              return const BillingQuestionsWidget();
            },
          );
        },
      ),
    );
  }
}
