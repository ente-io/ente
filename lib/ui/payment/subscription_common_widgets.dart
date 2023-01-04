

import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/subscription.dart';
import 'package:photos/ui/payment/billing_questions_widget.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/date_time_util.dart';

class SubscriptionHeaderWidget extends StatefulWidget {
  final bool? isOnboarding;
  final int? currentUsage;

  const SubscriptionHeaderWidget({
    Key? key,
    this.isOnboarding,
    this.currentUsage,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SubscriptionHeaderWidgetState();
  }
}

class _SubscriptionHeaderWidgetState extends State<SubscriptionHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.isOnboarding!) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Select your plan",
                  style: Theme.of(context).textTheme.headline4,
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "Ente preserves your memories, so they're always available to you, even if you lose your device ",
              style: Theme.of(context).textTheme.caption,
            ),
          ],
        ),
      );
    } else {
      return SizedBox(
        height: 72,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Current usage is ",
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                TextSpan(
                  text: formatBytes(widget.currentUsage!),
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1!
                      .copyWith(fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ),
      );
    }
  }
}

class ValidityWidget extends StatelessWidget {
  final Subscription? currentSubscription;

  const ValidityWidget({Key? key, this.currentSubscription}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentSubscription == null) {
      return const SizedBox.shrink();
    }
    final endDate = getDateAndMonthAndYear(
      DateTime.fromMicrosecondsSinceEpoch(currentSubscription!.expiryTime),
    );
    var message = "Renews on $endDate";
    if (currentSubscription!.productID == freeProductID) {
      message = "Free trial valid till $endDate";
    } else if (currentSubscription!.attributes?.isCancelled ?? false) {
      message = "Your subscription will be cancelled on $endDate";
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.caption,
      ),
    );
  }
}

class SubFaqWidget extends StatelessWidget {
  const SubFaqWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          showModalBottomSheet<void>(
            backgroundColor: Theme.of(context).colorScheme.bgColorForQuestions,
            barrierColor: Colors.black87,
            context: context,
            builder: (context) {
              return const BillingQuestionsWidget();
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(40),
          child: RichText(
            text: TextSpan(
              text: "Questions?",
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
