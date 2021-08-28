import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/subscription.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/date_time_util.dart';

import '../billing_questions_widget.dart';

class SubscriptionHeaderWidget extends StatefulWidget {
  final bool isOnboarding;
  final Future<int> usageFuture;

  const SubscriptionHeaderWidget({Key key, this.isOnboarding, this.usageFuture})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SubscriptionHeaderWidgetState();
  }
}

class _SubscriptionHeaderWidgetState extends State<SubscriptionHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.isOnboarding) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Text(
          "ente preserves your memories, so they're always available to you, even if you lose your device",
          style: TextStyle(
            color: Colors.white54,
            height: 1.2,
          ),
        ),
      );
    } else {
      return SizedBox(
        height: 50,
        child: FutureBuilder(
          future: widget.usageFuture,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("current usage is " + formatBytes(snapshot.data)),
              );
            } else if (snapshot.hasError) {
              return Container();
            } else {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: loadWidget,
              );
            }
          },
        ),
      );
    }
  }
}

class ValidityWidget extends StatelessWidget {
  final Subscription currentSubscription;

  const ValidityWidget({Key key, this.currentSubscription}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentSubscription == null) {
      return Container();
    }
    var endDate = getDateAndMonthAndYear(
        DateTime.fromMicrosecondsSinceEpoch(currentSubscription.expiryTime));
    var message = "renews on $endDate";
    if (currentSubscription.productID == kFreeProductID) {
      message = "free plan valid till $endDate";
    } else if (currentSubscription.attributes?.isCancelled ?? false) {
      message = "your subscription will be cancelled on $endDate";
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
    );
  }
}

class SubFaqWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          showModalBottomSheet<void>(
            backgroundColor: Color.fromRGBO(10, 15, 15, 1.0),
            barrierColor: Colors.black87,
            context: context,
            builder: (context) {
              return BillingQuestionsWidget();
            },
          );
        },
        child: Container(
          padding: EdgeInsets.all(40),
          child: RichText(
            text: TextSpan(
              text: "questions?",
              style: TextStyle(
                color: Colors.blue,
                fontFamily: 'Ubuntu',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
