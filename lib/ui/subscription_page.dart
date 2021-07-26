import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/billing_plan.dart';
import 'package:photos/models/subscription.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/expansion_card.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/progress_dialog.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPage extends StatefulWidget {
  final bool isOnboarding;

  const SubscriptionPage({
    this.isOnboarding = false,
    Key key,
  }) : super(key: key);

  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final _logger = Logger("SubscriptionPage");
  final _billingService = BillingService.instance;
  Subscription _currentSubscription;
  StreamSubscription _purchaseUpdateSubscription;
  ProgressDialog _dialog;
  Future<int> _usageFuture;
  bool _hasActiveSubscription;
  BillingPlans _plans;
  bool _hasLoadedData = false;

  @override
  void initState() {
    _billingService.setIsOnSubscriptionPage(true);
    _billingService.fetchSubscription().then((subscription) async {
      _currentSubscription = subscription;
      _hasActiveSubscription = _currentSubscription.isValid();
      _plans = await _billingService.getBillingPlans();
      _usageFuture = _billingService.fetchUsage();
      _hasLoadedData = true;
      setState(() {});
    });
    _setupPurchaseUpdateStreamListener();
    _dialog = createProgressDialog(context, "please wait...");
    super.initState();
  }

  void _setupPurchaseUpdateStreamListener() {
    _purchaseUpdateSubscription = InAppPurchaseConnection
        .instance.purchaseUpdatedStream
        .listen((purchases) async {
      if (!_dialog.isShowing()) {
        await _dialog.show();
      }
      for (final purchase in purchases) {
        _logger.info("Purchase status " + purchase.status.toString());
        if (purchase.status == PurchaseStatus.purchased) {
          try {
            final newSubscription = await _billingService.verifySubscription(
              purchase.productID,
              purchase.verificationData.serverVerificationData,
            );
            await InAppPurchaseConnection.instance.completePurchase(purchase);
            String text = "thank you for subscribing!";
            if (!widget.isOnboarding) {
              final isUpgrade = _hasActiveSubscription &&
                  newSubscription.storage > _currentSubscription.storage;
              final isDowngrade = _hasActiveSubscription &&
                  newSubscription.storage < _currentSubscription.storage;
              if (isUpgrade) {
                text = "your plan was successfully upgraded";
              } else if (isDowngrade) {
                text = "your plan was successfully downgraded";
              }
            }
            showToast(text);
            _currentSubscription = newSubscription;
            _hasActiveSubscription = _currentSubscription.isValid();
            setState(() {});
            await _dialog.hide();
            Bus.instance.fire(SubscriptionPurchasedEvent());
            if (widget.isOnboarding) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } catch (e) {
            _logger.warning("Could not complete payment ", e);
            await _dialog.hide();
            showErrorDialog(
                context,
                "payment failed",
                "please talk to " +
                    (Platform.isAndroid ? "PlayStore" : "AppStore") +
                    " support if you were charged");
            return;
          }
        } else if (Platform.isIOS && purchase.pendingCompletePurchase) {
          await InAppPurchaseConnection.instance.completePurchase(purchase);
          await _dialog.hide();
        } else if (purchase.status == PurchaseStatus.error) {
          await _dialog.hide();
        }
      }
    });
  }

  @override
  void dispose() {
    _purchaseUpdateSubscription.cancel();
    _billingService.setIsOnSubscriptionPage(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text("subscription"),
    );
    return Scaffold(
      appBar: appBar,
      body: _getBody(),
    );
  }

  Widget _getBody() {
    if (_hasLoadedData) {
      return _buildPlans();
    }
    return loadWidget;
  }

  Widget _buildPlans() {
    final widgets = <Widget>[];
    if (widget.isOnboarding) {
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Text(
          "ente preserves your memories, so they're always available to you, even if you lose your device",
          style: TextStyle(
            color: Colors.white54,
            height: 1.2,
          ),
        ),
      ));
    } else {
      widgets.add(
        SizedBox(
          height: 50,
          child: FutureBuilder(
            future: _usageFuture,
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
        ),
      );
    }
    final isActiveStripeSubscriber =
        _currentSubscription.paymentProvider == kStripe &&
            _currentSubscription.isValid();
    widgets.addAll([
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: isActiveStripeSubscriber
            ? _getStripePlanWidgets()
            : _getMobilePlanWidgets(),
      ),
      Padding(padding: EdgeInsets.all(8)),
    ]);

    if (_hasActiveSubscription) {
      widgets.add(
        Text(
          "valid till " +
              getDateAndMonthAndYear(DateTime.fromMicrosecondsSinceEpoch(
                  _currentSubscription.expiryTime)),
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      );
    }

    if (_hasActiveSubscription &&
        _currentSubscription.productID != kFreeProductID) {
      widgets.addAll([
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              if (isActiveStripeSubscriber) {
                return;
              }
              if (Platform.isAndroid) {
                launch(
                    "https://play.google.com/store/account/subscriptions?sku=" +
                        _currentSubscription.productID +
                        "&package=io.ente.photos");
              } else {
                launch("https://apps.apple.com/account/billing");
              }
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(40, 80, 40, 80),
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      text: isActiveStripeSubscriber
                          ? "visit web.ente.io to manage your subscription"
                          : "payment details",
                      style: TextStyle(
                        color: isActiveStripeSubscriber
                            ? Colors.white
                            : Colors.blue,
                        fontFamily: 'Ubuntu',
                        fontSize: 15,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ]);
    }
    if (widget.isOnboarding &&
        _currentSubscription.productID == kFreeProductID) {
      widgets.addAll([_getSkipButton(_plans.freePlan)]);
    }
    if (_currentSubscription.productID == kFreeProductID) {
      widgets.addAll([
        Align(
          alignment: Alignment.center,
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
        ),
      ]);
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widgets,
      ),
    );
  }

  List<Widget> _getStripePlanWidgets() {
    final List<Widget> planWidgets = [];
    BillingPlan currentPlan = _plans.plans
        .where((plan) => plan.stripeID == _currentSubscription.productID)
        .toList()[0];

    for (final plan in _plans.plans) {
      final productID = plan.stripeID;
      if (productID == null ||
          productID.isEmpty ||
          currentPlan.period != plan.period) {
        continue;
      }
      final isActive =
          _hasActiveSubscription && _currentSubscription.productID == productID;
      planWidgets.add(
        Material(
          child: InkWell(
            onTap: () async {
              if (isActive) {
                return;
              }
              showErrorDialog(context, "sorry",
                  "please visit web.ente.io to manage your subscription");
            },
            child: SubscriptionPlanWidget(
              storage: plan.storage,
              price: plan.price,
              period: plan.period,
              isActive: isActive,
            ),
          ),
        ),
      );
    }
    return planWidgets;
  }

  List<Widget> _getMobilePlanWidgets() {
    final List<Widget> planWidgets = [];
    if (_hasActiveSubscription &&
        _currentSubscription.productID == kFreeProductID) {
      planWidgets.add(
        SubscriptionPlanWidget(
          storage: _plans.freePlan.storage,
          price: "free",
          period: "",
          isActive: true,
        ),
      );
    }
    for (final plan in _plans.plans) {
      final productID = Platform.isAndroid ? plan.androidID : plan.iosID;
      if (productID == null || productID.isEmpty) {
        continue;
      }
      final isActive =
          _hasActiveSubscription && _currentSubscription.productID == productID;
      planWidgets.add(
        Material(
          child: InkWell(
            onTap: () async {
              if (isActive) {
                return;
              }
              await _dialog.show();
              if (_usageFuture != null) {
                final usage = await _usageFuture;
                if (usage > plan.storage) {
                  await _dialog.hide();
                  showErrorDialog(
                      context, "sorry", "you cannot downgrade to this plan");
                  return;
                }
              }
              final ProductDetailsResponse response =
                  await InAppPurchaseConnection.instance
                      .queryProductDetails({productID});
              if (response.notFoundIDs.isNotEmpty) {
                _logger.severe("Could not find products: " +
                    response.notFoundIDs.toString());
                await _dialog.hide();
                showGenericErrorDialog(context);
                return;
              }
              final isCrossGradingOnAndroid = Platform.isAndroid &&
                  _hasActiveSubscription &&
                  _currentSubscription.productID != kFreeProductID &&
                  _currentSubscription.productID != plan.androidID;
              if (isCrossGradingOnAndroid) {
                final existingProductDetailsResponse =
                    await InAppPurchaseConnection.instance
                        .queryProductDetails({_currentSubscription.productID});
                if (existingProductDetailsResponse.notFoundIDs.isNotEmpty) {
                  _logger.severe("Could not find existing products: " +
                      response.notFoundIDs.toString());
                  await _dialog.hide();
                  showGenericErrorDialog(context);
                  return;
                }
                final subscriptionChangeParam = ChangeSubscriptionParam(
                  oldPurchaseDetails: PurchaseDetails(
                    purchaseID: null,
                    productID: _currentSubscription.productID,
                    verificationData: null,
                    transactionDate: null,
                  ),
                );
                await InAppPurchaseConnection.instance.buyNonConsumable(
                  purchaseParam: PurchaseParam(
                    productDetails: response.productDetails[0],
                    changeSubscriptionParam: subscriptionChangeParam,
                  ),
                );
              } else {
                await InAppPurchaseConnection.instance.buyNonConsumable(
                  purchaseParam: PurchaseParam(
                    productDetails: response.productDetails[0],
                  ),
                );
              }
            },
            child: SubscriptionPlanWidget(
              storage: plan.storage,
              price: plan.price,
              period: plan.period,
              isActive: isActive,
            ),
          ),
        ),
      );
    }
    return planWidgets;
  }

  Widget _getSkipButton(FreePlan plan) {
    return Container(
      width: double.infinity,
      height: 64,
      margin: const EdgeInsets.fromLTRB(0, 30, 0, 30),
      padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
      child: button(
        "continue on free plan",
        fontSize: 16,
        onPressed: () async {
          showToast("thank you for signing up!");
          Bus.instance.fire(SubscriptionPurchasedEvent());
          Navigator.of(context).popUntil((route) => route.isFirst);
          BillingService.instance
              .verifySubscription(kFreeProductID, "", paymentProvider: "ente");
        },
      ),
    );
  }
}

class BillingQuestionsWidget extends StatelessWidget {
  const BillingQuestionsWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Network.instance
          .getDio()
          .get("https://static.ente.io/faq.json")
          .then((response) {
        final faqItems = <FaqItem>[];
        for (final item in response.data as List) {
          faqItems.add(FaqItem.fromMap(item));
        }
        return faqItems;
      }),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final faqs = <Widget>[];
          faqs.add(Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "faqs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ));
          for (final faq in snapshot.data) {
            faqs.add(FaqWidget(faq: faq));
          }
          faqs.add(Padding(
            padding: EdgeInsets.all(16),
          ));
          return SingleChildScrollView(
            child: Column(
              children: faqs,
            ),
          );
        } else {
          return loadWidget;
        }
      },
    );
  }
}

class FaqWidget extends StatelessWidget {
  const FaqWidget({
    Key key,
    @required this.faq,
  }) : super(key: key);

  final FaqItem faq;

  @override
  Widget build(BuildContext context) {
    return ExpansionCard(
      title: Text(faq.q),
      color: Theme.of(context).buttonColor,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Text(
            faq.a,
            style: TextStyle(
              height: 1.5,
            ),
          ),
        )
      ],
    );
  }
}

class FaqItem {
  final String q;
  final String a;
  FaqItem({
    this.q,
    this.a,
  });

  FaqItem copyWith({
    String q,
    String a,
  }) {
    return FaqItem(
      q: q ?? this.q,
      a: a ?? this.a,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'q': q,
      'a': a,
    };
  }

  factory FaqItem.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return FaqItem(
      q: map['q'],
      a: map['a'],
    );
  }

  String toJson() => json.encode(toMap());

  factory FaqItem.fromJson(String source) =>
      FaqItem.fromMap(json.decode(source));

  @override
  String toString() => 'FaqItem(q: $q, a: $a)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is FaqItem && o.q == q && o.a == a;
  }

  @override
  int get hashCode => q.hashCode ^ a.hashCode;
}

class SubscriptionPlanWidget extends StatelessWidget {
  const SubscriptionPlanWidget({
    Key key,
    @required this.storage,
    @required this.price,
    @required this.period,
    this.isActive = false,
  }) : super(key: key);

  final int storage;
  final String price;
  final String period;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 36, 10),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  color: Color(0xDFFFFFFF),
                  child: Container(
                    width: 100,
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                    child: Column(
                      children: [
                        Text(
                          convertBytesToReadableFormat(storage),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).cardColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Text(price + (period.isNotEmpty ? " per " + period : "")),
              Expanded(child: Container()),
              isActive
                  ? Expanded(
                      child: Icon(
                        Icons.check_circle,
                        color: Theme.of(context).buttonColor,
                      ),
                    )
                  : Container(),
            ],
          ),
          Divider(
            height: 1,
          ),
        ],
      ),
    );
  }
}
