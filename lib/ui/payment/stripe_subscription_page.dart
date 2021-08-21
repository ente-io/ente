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
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/billing_questions_widget.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/payment/payment_web_page.dart';
import 'package:photos/ui/payment/skip_subscription_widget.dart';
import 'package:photos/ui/payment/subscription_common_widgets.dart';
import 'package:photos/ui/payment/subscription_plan_widget.dart';
import 'package:photos/ui/progress_dialog.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

import '../web_page.dart';

class StripeSubscriptionPage extends StatefulWidget {
  final bool isOnboarding;

  const StripeSubscriptionPage({
    this.isOnboarding = false,
    Key key,
  }) : super(key: key);

  @override
  _StripeSubscriptionPageState createState() => _StripeSubscriptionPageState();
}

class _StripeSubscriptionPageState extends State<StripeSubscriptionPage> {
  final _logger = Logger("StripeSubscriptionPage");
  final _billingService = BillingService.instance;
  Subscription _currentSubscription;
  ProgressDialog _dialog;
  Future<int> _usageFuture;

  // indicates if user's subscription plan is still active
  bool _hasActiveSubscription;
  FreePlan _freePlan;
  List<BillingPlan> _plans = [];
  bool _hasLoadedData = false;
  bool _isActiveStripeSubscriber;
  bool _showYearlyPlan = false;

  @override
  void initState() {
    _fetchSub();
    _dialog = createProgressDialog(context, "please wait...");
    super.initState();
  }

  Future<void> _fetchSub() async {
    return _billingService.fetchSubscription().then((subscription) async {
      _currentSubscription = subscription;
      _showYearlyPlan = _currentSubscription.isYearlyPlan();
      _hasActiveSubscription = _currentSubscription.isValid();
      _isActiveStripeSubscriber =
          _currentSubscription.paymentProvider == kStripe &&
              _currentSubscription.isValid();
      _usageFuture = _billingService.fetchUsage();
      return _filterStripeForUI().then((value) {
        _hasLoadedData = true;
        setState(() {});
      });
    });
  }

  // _filterPlansForUI is used for initializing initState & plan toggle states
  Future<void> _filterStripeForUI() async {
    final billingPlans = await _billingService.getBillingPlans();
    _freePlan = billingPlans.freePlan;
    _plans = billingPlans.plans.where((plan) {
      if (plan.stripeID == null || plan.stripeID.isEmpty) {
        return false;
      }
      var isYearlyPlan = plan.period == 'year';
      return isYearlyPlan == _showYearlyPlan;
    }).toList();
    setState(() {});
  }

  FutureOr onWebPaymentGoBack(dynamic value) async {
    if (widget.isOnboarding) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      // refresh subscription
      await _dialog.show();
      try {
        await _fetchSub();
      } catch (e) {
        showToast("failed to refresh subscription");
      }
      await _dialog.hide();
    }
  }

  @override
  void dispose() {
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
          children: _getStripePlanWidgets()),
      Padding(padding: EdgeInsets.all(8)),
    ]);

    widgets.add(_showSubscriptionToggle());

    if (_hasActiveSubscription) {
      widgets.add(ValidityWidget(currentSubscription: _currentSubscription));
    }

    if (_currentSubscription.productID == kFreeProductID) {
      if (widget.isOnboarding) {
        widgets.add(SkipSubscriptionWidget(freePlan: _freePlan));
      }
      widgets.add(SubFaqWidget());
    }

    if (_hasActiveSubscription && _isActiveStripeSubscriber) {
      widgets.add(_stripeRenewOrCancelButton());
    }

    if (_hasActiveSubscription &&
        _currentSubscription.productID != kFreeProductID) {
      widgets.addAll([
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () async {
              switch (_currentSubscription.paymentProvider) {
                case kStripe:
                  await _launchStripePortal();
                  break;
                case kPlayStore:
                  launch(
                      "https://play.google.com/store/account/subscriptions?sku=" +
                          _currentSubscription.productID +
                          "&package=io.ente.photos");
                  break;
                case kAppStore:
                  launch("https://apps.apple.com/account/billing");
                  break;
                default:
                  _logger.severe(
                      "unexpected payment provider ", _currentSubscription);
              }
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(40, 80, 40, 80),
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      text: !_isActiveStripeSubscriber
                          ? "visit ${_currentSubscription.paymentProvider} to manage your subscription"
                          : "payment details",
                      style: TextStyle(
                        color: _isActiveStripeSubscriber
                            ? Colors.blue
                            : Colors.white,
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

  Future<void> _launchStripePortal() async {
    await _dialog.show();
    try {
      String url = await _billingService.getStripeCustomerPortalUrl();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return WebPage("payment details", url);
          },
        ),
      ).then((value) => onWebPaymentGoBack);
    } catch (e) {
      await _dialog.hide();
      showGenericErrorDialog(context);
    }
    await _dialog.hide();
  }

  Widget _stripeRenewOrCancelButton() {
    bool isRenewCancelled =
        _currentSubscription.attributes?.isCancelled ?? false;
    String title =
        isRenewCancelled ? "renew subscription" : "cancel subscription";
    return TextButton(
      child: Text(
        title,
        style: TextStyle(
          color: (isRenewCancelled ? Colors.greenAccent : Colors.white)
          .withOpacity(isRenewCancelled ? 1.0: 0.4),
        ),
      ),
      onPressed: () async {
        var result = await showChoiceDialog(context, title,
            isRenewCancelled
                ? 'are you sure you want to renew?'
                : 'are you sure you want to cancel?',
            firstAction: 'yes',
            secondAction: 'no');
        if (result == DialogUserChoice.firstChoice) {
          toggleStripeSubscription(isRenewCancelled);
        }
      },
    );
  }

  Future<void> toggleStripeSubscription(bool isRenewCancelled) async {
    await _dialog.show();
    try {
      isRenewCancelled
          ? await _billingService.activateStripeSubscription()
          : await _billingService.cancelStripeSubscription();
      await _fetchSub();
    } catch (e) {
      showToast(isRenewCancelled ? 'failed to renew' : 'failed to cancel');
    }
    await _dialog.hide();
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
              if (!_isActiveStripeSubscriber &&
                  _currentSubscription.productID != kFreeProductID) {
                showErrorDialog(context, "sorry",
                    "please cancel your existing subscription from ${_currentSubscription.paymentProvider} first");
                return;
              }
              await _dialog.show();
              if (_usageFuture != null) {
                final usage = await _usageFuture;
                await _dialog.hide();
                if (usage > plan.storage) {
                  showErrorDialog(
                      context, "sorry", "you cannot downgrade to this plan");
                  return;
                }
              }
              String stripPurChaseAction = 'buy';
              if (_isActiveStripeSubscriber) {
                // confirm if user wants to change plan or not
                var result = await showChoiceDialog(
                    context,
                    "confirm plan change",
                    "are you sure you want to change your plan?",
                    firstAction: "yes",
                    secondAction: 'no');
                if (result != DialogUserChoice.firstChoice) {
                  return;
                }
                stripPurChaseAction = 'update';
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return PaymentWebPage(
                      planId: plan.stripeID,
                      actionType: stripPurChaseAction,
                    );
                  },
                ),
              ).then((value) => onWebPaymentGoBack(value));
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

  Widget _showSubscriptionToggle() {
    Text _planText(String title, bool reduceOpacity) {
      return Text(
        title,
        style: TextStyle(
          color: Theme.of(context)
              .buttonColor
              .withOpacity(reduceOpacity ? 0.5 : 1.0),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
      margin: EdgeInsets.only(bottom: 12),
      // color: Color.fromRGBO(10, 40, 40, 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _planText("monthly plans", _showYearlyPlan),
          Switch(
            value: _showYearlyPlan,
            onChanged: (value) async {
              _showYearlyPlan = value;
              await _filterStripeForUI();
            },
          ),
          _planText("yearly plans", !_showYearlyPlan)
        ],
      ),
    );
  }

  void _addCurrentPlanWidget(List<Widget> planWidgets) {
    // don't add current plan if it's monthly plan but UI is showing yearly plans
    // and vice versa.
    if (_showYearlyPlan != _currentSubscription.isYearlyPlan() &&
        _currentSubscription.productID != kFreeProductID) {
      return;
    }
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
