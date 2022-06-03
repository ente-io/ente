import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/billing_plan.dart';
import 'package:photos/models/subscription.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/utils/toast_util.dart';

class SkipSubscriptionWidget extends StatelessWidget {
  const SkipSubscriptionWidget({
    Key key,
    @required this.freePlan,
  }) : super(key: key);

  final FreePlan freePlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      margin: const EdgeInsets.fromLTRB(0, 30, 0, 0),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: OutlinedButton(
        child: Text("Continue on free plan"),
        style: Theme.of(context).outlinedButtonTheme.style.copyWith(
          textStyle: MaterialStateProperty.resolveWith<TextStyle>(
            (Set<MaterialState> states) {
              return Theme.of(context).textTheme.subtitle1;
            },
          ),
        ),
        // fontSize: 16,
        onPressed: () async {
          showToast("Thank you for signing up!");
          Bus.instance.fire(SubscriptionPurchasedEvent());
          Navigator.of(context).popUntil((route) => route.isFirst);
          BillingService.instance
              .verifySubscription(kFreeProductID, "", paymentProvider: "ente");
        },
      ),
    );
  }
}
