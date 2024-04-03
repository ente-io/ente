import 'dart:async';

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/billing_plan.dart';
import 'package:photos/models/subscription.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/billing_service.dart';
import "package:photos/services/update_service.dart";
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
import "package:photos/ui/payment/view_add_on_widget.dart";
import "package:photos/utils/data_util.dart";
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
  bool _hideCurrentPlanSelection = false;
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
      _hideCurrentPlanSelection =
          (_currentSubscription?.attributes?.isCancelled ?? false) &&
              userDetails.hasPaidAddon();
      _hasActiveSubscription = _currentSubscription!.isValid();
      _isStripeSubscriber = _currentSubscription!.paymentProvider == stripe;

      if (_isStripeSubscriber && _currentSubscription!.isPastDue()) {
        _redirectToPaymentPortal();
      }

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
              color: Theme.of(context).colorScheme.background,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
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
                title: Text("${S.of(context).subscription}${kDebugMode ? ' '
                    'Stripe' : ''}"),
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
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    if (!_isLoading) {
      _isLoading = true;
      _dialog = createProgressDialog(context, S.of(context).pleaseWait);
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

    if (_currentSubscription != null) {
      widgets.add(
        ValidityWidget(
          currentSubscription: _currentSubscription,
          bonusData: _userDetails.bonusData,
        ),
      );
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
            captionedTextWidget: CaptionedTextWidget(
              title: S.of(context).paymentDetails,
            ),
            menuItemColor: colorScheme.fillFaint,
            trailingWidget: Icon(
              Icons.chevron_right_outlined,
              color: colorScheme.strokeBase,
            ),
            singleBorderRadius: 4,
            alignCaptionedTextToLeft: true,
            onTap: () async {
              _redirectToPaymentPortal();
            },
          ),
        ),
      );
    }

    if (!widget.isOnboarding) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: S.of(context).manageFamily,
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
              _billingService.launchFamilyPortal(context, _userDetails);
            },
          ),
        ),
      );
      widgets.add(ViewAddOnButton(_userDetails.bonusData));
      widgets.add(const SizedBox(height: 80));
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widgets,
      ),
    );
  }

  // _redirectToPaymentPortal action allows the user to update
  // their stripe payment details
  void _redirectToPaymentPortal() async {
    final String paymentProvider = _currentSubscription!.paymentProvider;
    switch (_currentSubscription!.paymentProvider) {
      case stripe:
        await _launchStripePortal();
        break;
      case playStore:
        unawaited(
          launchUrlString(
            "https://play.google.com/store/account/subscriptions?sku=" +
                _currentSubscription!.productID +
                "&package=io.ente.photos",
          ),
        );
        break;
      case appStore:
        unawaited(launchUrlString("https://apps.apple.com/account/billing"));
        break;
      default:
        final String capitalizedWord = paymentProvider.isNotEmpty
            ? '${paymentProvider[0].toUpperCase()}${paymentProvider.substring(1).toLowerCase()}'
            : '';
        await showErrorDialog(
          context,
          S.of(context).sorry,
          S.of(context).contactToManageSubscription(capitalizedWord),
        );
    }
  }

  Future<void> _launchStripePortal() async {
    await _dialog.show();
    try {
      final String url = await _billingService.getStripeCustomerPortalUrl();
      await _dialog.hide();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return WebPage(S.of(context).paymentDetails, url);
          },
        ),
      ).then((value) => onWebPaymentGoBack);
    } catch (e) {
      await _dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Widget _stripeRenewOrCancelButton() {
    final bool isRenewCancelled =
        _currentSubscription!.attributes?.isCancelled ?? false;
    if (isRenewCancelled && _userDetails.hasPaidAddon()) {
      return const SizedBox.shrink();
    }
    final String title = isRenewCancelled
        ? S.of(context).renewSubscription
        : S.of(context).cancelSubscription;
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
            body: S.of(context).areYouSureYouWantToRenew,
            firstButtonLabel: S.of(context).yesRenew,
          );
          confirmAction = choice!.action == ButtonAction.first;
        } else {
          final choice = await showChoiceDialog(
            context,
            title: title,
            body: S.of(context).areYouSureYouWantToCancel,
            firstButtonLabel: S.of(context).yesCancel,
            secondButtonLabel: S.of(context).no,
            isCritical: true,
          );
          confirmAction = choice!.action == ButtonAction.first;
        }
        if (confirmAction) {
          await toggleStripeSubscription(isRenewCancelled);
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
        isAutoRenewDisabled
            ? S.of(context).failedToRenew
            : S.of(context).failedToCancel,
      );
    }
    await _dialog.hide();
    if (!isAutoRenewDisabled && mounted) {
      await showTextInputDialog(
        context,
        title: S.of(context).askCancelReason,
        submitButtonLabel: S.of(context).send,
        hintText: S.of(context).optionalAsShortAsYouLike,
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
                await showErrorDialog(
                  context,
                  S.of(context).sorry,
                  S.of(context).cancelOtherSubscription(
                        _currentSubscription!.paymentProvider,
                      ),
                );
                return;
              }
              final int addOnBonus =
                  _userDetails.bonusData?.totalAddOnBonus() ?? 0;
              if (_userDetails.getFamilyOrPersonalUsage() >
                  (plan.storage + addOnBonus)) {
                logger.warning(
                  " familyUsage ${convertBytesToReadableFormat(_userDetails.getFamilyOrPersonalUsage())}"
                  " plan storage ${convertBytesToReadableFormat(plan.storage)} "
                  "addOnBonus ${convertBytesToReadableFormat(addOnBonus)},"
                  "overshooting by ${convertBytesToReadableFormat(_userDetails.getFamilyOrPersonalUsage() - (plan.storage + addOnBonus))}",
                );
                await showErrorDialog(
                  context,
                  S.of(context).sorry,
                  S.of(context).youCannotDowngradeToThisPlan,
                );
                return;
              }
              String stripPurChaseAction = 'buy';
              if (_isStripeSubscriber && _hasActiveSubscription) {
                // confirm if user wants to change plan or not
                final result = await showChoiceDialog(
                  context,
                  title: S.of(context).confirmPlanChange,
                  body: S.of(context).areYouSureYouWantToChangeYourPlan,
                  firstButtonLabel: S.of(context).yes,
                );
                if (result!.action == ButtonAction.first) {
                  stripPurChaseAction = 'update';
                } else {
                  return;
                }
              }
              await Navigator.push(
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
              isActive: isActive && !_hideCurrentPlanSelection,
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
                planText(S.of(context).monthly, _showYearlyPlan),
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
                planText(S.of(context).yearly, !_showYearlyPlan),
              ],
            ),
          ),
          _isFreePlanUser() && !UpdateService.instance.isPlayStoreFlavor()
              ? Text(
                  S.of(context).twoMonthsFreeOnYearlyPlans,
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
            isActive: !_hasActiveSubscription,
          ),
        ),
      ),
    );
  }
}
