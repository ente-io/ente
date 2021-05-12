import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:photos/ui/expansion_card.dart';
import 'package:photos/ui/progress_dialog.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/billing_plan.dart';
import 'package:photos/models/subscription.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

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

  @override
  void initState() {
    _billingService.setIsOnSubscriptionPage(true);
    _currentSubscription = _billingService.getSubscription();
    _hasActiveSubscription =
        _currentSubscription != null && _currentSubscription.isValid();
    if (_currentSubscription != null) {
      _usageFuture = _billingService.fetchUsage();
    }

    _dialog = createProgressDialog(context, "please wait...");

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
            Bus.instance.fire(SubscriptionPurchasedEvent());
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
            if (_currentSubscription != null) {
              _currentSubscription = _billingService.getSubscription();
              _hasActiveSubscription = _currentSubscription != null &&
                  _currentSubscription.isValid();
              setState(() {});
            } else {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
            await _dialog.hide();
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
    super.initState();
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
      body: _getBody(appBar.preferredSize.height),
    );
  }

  Widget _getBody(final appBarSize) {
    return FutureBuilder<BillingPlans>(
      future: _billingService.getBillingPlans(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return _buildPlans(context, snapshot.data, appBarSize);
        } else if (snapshot.hasError) {
          return Text("Oops, something went wrong.");
        } else {
          return loadWidget;
        }
      },
    );
  }

  Widget _buildPlans(
      BuildContext context, BillingPlans plans, final appBarSize) {
    List<Widget> planWidgets = _getPlanWidgets(plans, context);
    final pageSize = MediaQuery.of(context).size.height;
    final notifySize = MediaQuery.of(context).padding.top;
    final widgets = List<Widget>();
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
      widgets.add(Container(
        height: 50,
        child: FutureBuilder(
          future: _usageFuture,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("current usage is " +
                    convertBytesToGBs(snapshot.data).toString() +
                    " GB"),
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
      ));
    }
    widgets.addAll([
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: planWidgets,
      ),
      Padding(padding: EdgeInsets.all(8)),
    ]);

    if (_hasActiveSubscription &&
        _currentSubscription.productID != kFreeProductID) {
      widgets.addAll([
        Expanded(child: Container()),
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
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
              padding: EdgeInsets.all(80),
              child: Column(
                children: [
                  Text(
                    "next renewal on " +
                        getDateAndMonthAndYear(
                            DateTime.fromMicrosecondsSinceEpoch(
                                _currentSubscription.expiryTime)),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(8)),
                  RichText(
                    text: TextSpan(
                      text: "payment details",
                      style: TextStyle(
                        color: Colors.blue,
                        fontFamily: 'Ubuntu',
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]);
    } else {
      widgets.addAll([
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              showModalBottomSheet<void>(
                backgroundColor: Colors.grey[900],
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
        Expanded(child: Container()),
      ]);
    }
    if (widget.isOnboarding &&
        (_currentSubscription == null ||
            _currentSubscription.productID == kFreeProductID)) {
      widgets.addAll([_getSkipButton(plans.freePlan)]);
    }
    return SingleChildScrollView(
      child: Container(
        height: pageSize - (appBarSize + notifySize),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: widgets,
        ),
      ),
    );
  }

  List<Widget> _getPlanWidgets(BillingPlans plans, BuildContext context) {
    final planWidgets = List<Widget>();
    if (!widget.isOnboarding &&
        _hasActiveSubscription &&
        _currentSubscription.productID == kFreeProductID) {
      planWidgets.add(
        SubscriptionPlanWidget(
          storage: plans.freePlan.storage,
          price: "free",
          period: "",
          isActive: true,
        ),
      );
    }
    for (final plan in plans.plans) {
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
              if (_currentSubscription.paymentProvider == kStripe) {
                showErrorDialog(context, "sorry",
                    "please visit photos.ente.io to manage your subscription");
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
                      .queryProductDetails([productID].toSet());
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
                    await InAppPurchaseConnection.instance.queryProductDetails(
                        [_currentSubscription.productID].toSet());
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

  GestureDetector _getSkipButton(FreePlan plan) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
        margin: EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            Icon(
              Icons.fast_forward_outlined,
              color: Colors.white.withOpacity(0.8),
            ),
            Text(
              "skip",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        AlertDialog alert = AlertDialog(
          title: Text("sure?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "you will only be able to backup " +
                    convertBytesToReadableFormat(plan.storage) +
                    " for the next " +
                    plan.duration.toString() +
                    " " +
                    plan.period,
                style: TextStyle(
                  height: 1.4,
                ),
              ),
              Padding(padding: EdgeInsets.all(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: Text(
                      "review plans",
                      style: TextStyle(color: Theme.of(context).buttonColor),
                    ),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop('dialog');
                    },
                  ),
                  TextButton(
                    child: Text(
                      "ok",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      if (widget.isOnboarding) {
                        showToast("thank you for signing up!");
                        Bus.instance.fire(SubscriptionPurchasedEvent());
                      }
                      Navigator.of(context, rootNavigator: true).pop('dialog');
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ],
              ),
            ],
          ),
        );

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        );
      },
    );
  }
}

class BillingQuestionsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Network.instance
          .getDio()
          .get("https://static.ente.io/faq.json")
          .then((response) {
        final faqItems = List<FaqItem>();
        for (final item in response.data as List) {
          faqItems.add(FaqItem.fromMap(item));
        }
        return faqItems;
      }),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final faqs = List<Widget>();
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
          return Container(
            child: SingleChildScrollView(
              child: Column(
                children: faqs,
              ),
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

  final faq;

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
