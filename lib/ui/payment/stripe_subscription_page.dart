import 'dart:async';

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/billing_plan.dart';
import 'package:photos/models/subscription.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/user_service.dart';
import "package:photos/theme/colors.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/bottom_shadow.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import 'package:photos/ui/common/web_page.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import 'package:photos/ui/payment/child_subscription_widget.dart';
import 'package:photos/ui/payment/payment_web_page.dart';
import 'package:photos/ui/payment/skip_subscription_widget.dart';
import 'package:photos/ui/payment/subscription_common_widgets.dart';
import 'package:photos/ui/payment/subscription_plan_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

class StripeSubscriptionPage extends StatefulWidget {
  final bool isOnboarding;

  const StripeSubscriptionPage({
    this.isOnboarding = false,
    Key? key,
  }) : super(key: key);

  @override
  State<StripeSubscriptionPage> createState() => _StripeSubscriptionPageState();
}

class _StripeSubscriptionPageState extends State<StripeSubscriptionPage> {
  final _billingService = BillingService.instance;
  final _userService = UserService.instance;
  Subscription? _currentSubscription;
  late ProgressDialog _dialog;
  late UserDetails _userDetails;

  // indicates if user's subscription plan is still active
  late bool _hasActiveSubscription;
  late FreePlan _freePlan;
  List<BillingPlan> _plans = [];
  bool _hasLoadedData = false;
  bool _isLoading = false;
  bool _isStripeSubscriber = false;
  bool _showYearlyPlan = false;
  EnteColorScheme colorScheme = darkScheme;
  final Logger logger = Logger("StripeSubscriptionPage");

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchSub() async {
    return _userService
        .getUserDetailsV2(memoryCount: false)
        .then((userDetails) async {
      _userDetails = userDetails;
      _currentSubscription = userDetails.subscription;
      _showYearlyPlan = _currentSubscription!.isYearlyPlan();
      _hasActiveSubscription = _currentSubscription!.isValid();
      _isStripeSubscriber = _currentSubscription!.paymentProvider == stripe;
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
      if (plan.stripeID.isEmpty) {
        return false;
      }
      final isYearlyPlan = plan.period == 'year';
      return isYearlyPlan == _showYearlyPlan;
    }).toList();
    setState(() {});
  }

  FutureOr onWebPaymentGoBack(dynamic value) async {
    // refresh subscription
    await _dialog.show();
    try {
      await _fetchSub();
    } catch (e) {
      showToast(context, "Failed to refresh subscription");
    }
    await _dialog.hide();

    // verify user has subscribed before redirecting to main page
    if (widget.isOnboarding &&
        _currentSubscription != null &&
        _currentSubscription!.isValid() &&
        _currentSubscription!.productID != freeProductID) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    colorScheme = getEnteColorScheme(context);
    final appBar = PreferredSize(
      preferredSize: const Size(double.infinity, 60),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).backgroundColor,
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: widget.isOnboarding
            ? AppBar(
                elevation: 0,
                title: Hero(
                  tag: "subscription",
                  child: StepProgressIndicator(
                    totalSteps: 4,
                    currentStep: 4,
                    selectedColor:
                        Theme.of(context).colorScheme.greenAlternative,
                    roundedEdges: const Radius.circular(10),
                    unselectedColor: Theme.of(context)
                        .colorScheme
                        .stepProgressUnselectedColor,
                  ),
                ),
              )
            : AppBar(
                elevation: 0,
                title: const Text("Subscription${kDebugMode ? ' Stripe' : ''}"),
              ),
      ),
    );
    return Scaffold(
      appBar: appBar,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _getBody(),
          const BottomShadowWidget(
            offsetDy: 40,
          )
        ],
      ),
    );
  }

  Widget _getBody() {
    if (!_isLoading) {
      _isLoading = true;
      _dialog = createProgressDialog(context, "Please wait...");
      _fetchSub();
    }
    if (_hasLoadedData) {
      if (_userDetails.isPartOfFamily() && !_userDetails.isFamilyAdmin()) {
        return ChildSubscriptionWidget(userDetails: _userDetails);
      } else {
        return _buildPlans();
      }
    }
    return const EnteLoadingWidget();
  }

  Widget _buildPlans() {
    final widgets = <Widget>[];

    widgets.add(
      SubscriptionHeaderWidget(
        isOnboarding: widget.isOnboarding,
        currentUsage: _userDetails.getFamilyOrPersonalUsage(),
      ),
    );

    widgets.addAll([
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _getStripePlanWidgets(),
      ),
      const Padding(padding: EdgeInsets.all(4)),
    ]);

    widgets.add(_showSubscriptionToggle());

    if (_hasActiveSubscription) {
      widgets.add(ValidityWidget(currentSubscription: _currentSubscription));
    }

    if (_currentSubscription!.productID == freeProductID) {
      if (widget.isOnboarding) {
        widgets.add(SkipSubscriptionWidget(freePlan: _freePlan));
      }
      widgets.add(
        SubFaqWidget(isOnboarding: widget.isOnboarding),
      );
    }

    // only active subscription can be renewed/canceled
    if (_hasActiveSubscription && _isStripeSubscriber) {
      widgets.add(_stripeRenewOrCancelButton());
    }

    if (_currentSubscription!.productID != freeProductID) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 4),
          child: MenuItemWidget(
            captionedTextWidget: const CaptionedTextWidget(
              title: "Payment details",
            ),
            menuItemColor: colorScheme.fillFaint,
            trailingWidget: Icon(
              Icons.chevron_right_outlined,
              color: colorScheme.strokeBase,
            ),
            singleBorderRadius: 4,
            alignCaptionedTextToLeft: true,
            onTap: () async {
              _onStripSupportedPaymentDetailsTap();
            },
          ),
        ),
      );
    }

    if (!widget.isOnboarding) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          child: MenuItemWidget(
            captionedTextWidget: const CaptionedTextWidget(
              title: "Manage Family",
            ),
            menuItemColor: colorScheme.fillFaint,
            trailingWidget: Icon(
              Icons.chevron_right_outlined,
              color: colorScheme.strokeBase,
            ),
            singleBorderRadius: 4,
            alignCaptionedTextToLeft: true,
            onTap: () async {
              _billingService.launchFamilyPortal(context, _userDetails);
            },
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widgets,
      ),
    );
  }

  // _onStripSupportedPaymentDetailsTap action allows the user to update
  // their stripe payment details
  void _onStripSupportedPaymentDetailsTap() async {
    final String paymentProvider = _currentSubscription!.paymentProvider;
    switch (_currentSubscription!.paymentProvider) {
      case stripe:
        await _launchStripePortal();
        break;
      case playStore:
        launchUrlString(
          "https://play.google.com/store/account/subscriptions?sku=" +
              _currentSubscription!.productID +
              "&package=io.ente.photos",
        );
        break;
      case appStore:
        launchUrlString("https://apps.apple.com/account/billing");
        break;
      default:
        final String capitalizedWord = paymentProvider.isNotEmpty
            ? '${paymentProvider[0].toUpperCase()}${paymentProvider.substring(1).toLowerCase()}'
            : '';
        showErrorDialog(
          context,
          "Sorry",
          "Please contact us at support@ente.io to manage your "
              "$capitalizedWord subscription.",
        );
    }
  }

  Future<void> _launchStripePortal() async {
    await _dialog.show();
    try {
      final String url = await _billingService.getStripeCustomerPortalUrl();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return WebPage("Payment details", url);
          },
        ),
      ).then((value) => onWebPaymentGoBack);
    } catch (e) {
      await _dialog.hide();
      showGenericErrorDialog(context: context);
    }
    await _dialog.hide();
  }

  Widget _stripeRenewOrCancelButton() {
    final bool isRenewCancelled =
        _currentSubscription!.attributes?.isCancelled ?? false;
    final String title =
        isRenewCancelled ? "Renew subscription" : "Cancel subscription";
    return TextButton(
      child: Text(
        title,
        style: TextStyle(
          color: (isRenewCancelled
              ? colorScheme.primary700
              : colorScheme.textMuted),
        ),
      ),
      onPressed: () async {
        bool confirmAction = false;
        if (isRenewCancelled) {
          final choice = await showChoiceDialog(
            context,
            title: title,
            body: "Are you sure you want to renew?",
            firstButtonLabel: "Yes, Renew",
          );
          confirmAction = choice!.action == ButtonAction.first;
        } else {
          final choice = await showChoiceDialog(
            context,
            title: title,
            body: "Are you sure you want to cancel?",
            firstButtonLabel: "Yes, cancel",
            secondButtonLabel: "No",
            isCritical: true,
          );
          confirmAction = choice!.action == ButtonAction.first;
        }
        if (confirmAction) {
          toggleStripeSubscription(isRenewCancelled);
        }
      },
    );
  }

  // toggleStripeSubscription, based on current auto renew status, will
  // toggle the auto renew status of the user's subscription
  Future<void> toggleStripeSubscription(bool isAutoRenewDisabled) async {
    await _dialog.show();
    try {
      isAutoRenewDisabled
          ? await _billingService.activateStripeSubscription()
          : await _billingService.cancelStripeSubscription();
      await _fetchSub();
    } catch (e) {
      showShortToast(
        context,
        isAutoRenewDisabled ? 'Failed to renew' : 'Failed to cancel',
      );
    }
    await _dialog.hide();
    if (!isAutoRenewDisabled && mounted) {
      await showTextInputDialog(
        context,
        title: "Your subscription was cancelled. Would you like to share the "
            "reason?",
        submitButtonLabel: "Send",
        hintText: "Optional, as short as you like...",
        alwaysShowSuccessState: true,
        textCapitalization: TextCapitalization.words,
        onSubmit: (String text) async {
          // indicates user cancelled the rename request
          if (text == "" || text.trim().isEmpty) {
            return;
          }
          try {
            await UserService.instance.sendFeedback(context, text);
          } catch (e, s) {
            logger.severe("Failed to send feedback", e, s);
          }
        },
      );
    }
  }

  List<Widget> _getStripePlanWidgets() {
    final List<Widget> planWidgets = [];
    bool foundActivePlan = false;
    for (final plan in _plans) {
      final productID = plan.stripeID;
      if (productID.isEmpty) {
        continue;
      }
      final isActive = _hasActiveSubscription &&
          _currentSubscription!.productID == productID;
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
              // prompt user to cancel their active subscription form other
              // payment providers
              if (!_isStripeSubscriber &&
                  _hasActiveSubscription &&
                  _currentSubscription!.productID != freeProductID) {
                showErrorDialog(
                  context,
                  "Sorry",
                  "Please cancel your existing subscription from "
                      "${_currentSubscription!.paymentProvider} first",
                );
                return;
              }
              if (_userDetails.getFamilyOrPersonalUsage() > plan.storage) {
                showErrorDialog(
                  context,
                  "Sorry",
                  "You cannot downgrade to this plan",
                );
                return;
              }
              String stripPurChaseAction = 'buy';
              if (_isStripeSubscriber && _hasActiveSubscription) {
                // confirm if user wants to change plan or not
                final result = await showChoiceDialog(
                  context,
                  title: "Confirm plan change",
                  body: "Are you sure you want to change your plan?",
                  firstButtonLabel: "Yes",
                );
                if (result!.action == ButtonAction.first) {
                  stripPurChaseAction = 'update';
                } else {
                  return;
                }
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
    if (!foundActivePlan && _hasActiveSubscription) {
      _addCurrentPlanWidget(planWidgets);
    }
    return planWidgets;
  }

  bool _isFreePlanUser() {
    return _currentSubscription != null &&
        freeProductID == _currentSubscription!.productID;
  }

  Widget _showSubscriptionToggle() {
    Widget planText(String title, bool reduceOpacity) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, right: 4),
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(reduceOpacity ? 0.5 : 1.0),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          RepaintBoundary(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                planText("Monthly", _showYearlyPlan),
                Switch(
                  value: _showYearlyPlan,
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.white,
                  activeTrackColor: getEnteColorScheme(context).strokeMuted,
                  onChanged: (value) async {
                    _showYearlyPlan = value;
                    await _filterStripeForUI();
                  },
                ),
                planText("Yearly", !_showYearlyPlan),
              ],
            ),
          ),
          _isFreePlanUser()
              ? Text(
                  "2 months free on yearly plans",
                  style: getEnteTextTheme(context).miniMuted,
                )
              : const SizedBox.shrink(),
          const Padding(padding: EdgeInsets.all(8)),
        ],
      ),
    );
  }

  void _addCurrentPlanWidget(List<Widget> planWidgets) {
    // don't add current plan if it's monthly plan but UI is showing yearly plans
    // and vice versa.
    if (_showYearlyPlan != _currentSubscription!.isYearlyPlan() &&
        _currentSubscription!.productID != freeProductID) {
      return;
    }
    int activePlanIndex = 0;
    for (; activePlanIndex < _plans.length; activePlanIndex++) {
      if (_plans[activePlanIndex].storage > _currentSubscription!.storage) {
        break;
      }
    }
    planWidgets.insert(
      activePlanIndex,
      Material(
        child: InkWell(
          onTap: () {},
          child: SubscriptionPlanWidget(
            storage: _currentSubscription!.storage,
            price: _currentSubscription!.price,
            period: _currentSubscription!.period,
            isActive: true,
          ),
        ),
      ),
    );
  }
}
