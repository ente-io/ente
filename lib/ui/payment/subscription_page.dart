import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/billing_plan.dart';
import 'package:photos/models/subscription.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/ui/billing_questions_widget.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/payment/skip_subscription_widget.dart';
import 'package:photos/ui/payment/subscription_common_widgets.dart';
import 'package:photos/ui/payment/subscription_plan_widget.dart';
import 'package:photos/ui/progress_dialog.dart';
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
  FreePlan _freePlan;
  List<BillingPlan> _plans;
  bool _hasLoadedData = false;
  bool _isActiveStripeSubscriber;

  @override
  void initState() {
    _billingService.setIsOnSubscriptionPage(true);
    _billingService.fetchSubscription().then((subscription) async {
      _currentSubscription = subscription;
      _hasActiveSubscription = _currentSubscription.isValid();
      final billingPlans = await _billingService.getBillingPlans();
      _isActiveStripeSubscriber =
          _currentSubscription.paymentProvider == kStripe &&
              _currentSubscription.isValid();
      _plans = billingPlans.plans.where((plan) {
        final productID = _isActiveStripeSubscriber
            ? plan.stripeID
            : Platform.isAndroid
            ? plan.androidID
            : plan.iosID;
        return productID != null && productID.isNotEmpty;
      }).toList();
      _freePlan = billingPlans.freePlan;
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
    widgets.add(SubscriptionHeaderWidget(
      isOnboarding: widget.isOnboarding,
      usageFuture: _usageFuture,
    ));

    widgets.addAll([
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _isActiveStripeSubscriber
            ? _getStripePlanWidgets()
            : _getMobilePlanWidgets(),
      ),
      Padding(padding: EdgeInsets.all(8)),
    ]);

    if (_hasActiveSubscription) {
      widgets.add(ValidityWidget(currentSubscription: _currentSubscription));
    }

    if ( _currentSubscription.productID == kFreeProductID) {
      if (widget.isOnboarding) {
        widgets.add(SkipSubscriptionWidget(freePlan: _freePlan));
      }
      widgets.add(SubFaqWidget());
    }

    if (_hasActiveSubscription &&
        _currentSubscription.productID != kFreeProductID) {
      widgets.addAll([
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              if (_isActiveStripeSubscriber) {
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
                      text: _isActiveStripeSubscriber
                          ? "visit web.ente.io to manage your subscription"
                          : "payment details",
                      style: TextStyle(
                        color: _isActiveStripeSubscriber
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
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widgets,
      ),
    );
  }

  List<Widget> _getStripePlanWidgets() {
    final List<Widget> planWidgets = [];
    bool foundActivePlan = false;
    for (final plan in _plans) {
      final productID = plan.stripeID;
      if (productID == null || productID.isEmpty) {
        continue;
      }
      final isActive =
          _hasActiveSubscription && _currentSubscription.productID == productID;
      if (isActive) {
        foundActivePlan = true;
      }
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
    if (!foundActivePlan) {
      _addCurrentPlanWidget(planWidgets);
    }
    return planWidgets;
  }

  List<Widget> _getMobilePlanWidgets() {
    bool foundActivePlan = false;
    final List<Widget> planWidgets = [];
    if (_hasActiveSubscription &&
        _currentSubscription.productID == kFreeProductID) {
      foundActivePlan = true;
      planWidgets.add(
        SubscriptionPlanWidget(
          storage: _freePlan.storage,
          price: "free",
          period: "",
          isActive: true,
        ),
      );
    }
    for (final plan in _plans) {
      final productID = Platform.isAndroid ? plan.androidID : plan.iosID;
      final isActive =
          _hasActiveSubscription && _currentSubscription.productID == productID;
      if (isActive) {
        foundActivePlan = true;
      }
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
    if (!foundActivePlan) {
      _addCurrentPlanWidget(planWidgets);
    }
    return planWidgets;
  }

  void _addCurrentPlanWidget(List<Widget> planWidgets) {
    int activePlanIndex = 0;
    for (; activePlanIndex < _plans.length; activePlanIndex++) {
      if (_plans[activePlanIndex].storage > _currentSubscription.storage) {
        break;
      }
    }
    planWidgets.insert(
      activePlanIndex,
      Material(
        child: InkWell(
          onTap: () {},
          child: SubscriptionPlanWidget(
            storage: _currentSubscription.storage,
            price: _currentSubscription.price,
            period: _currentSubscription.period,
            isActive: true,
          ),
        ),
      ),
    );
  }
}

