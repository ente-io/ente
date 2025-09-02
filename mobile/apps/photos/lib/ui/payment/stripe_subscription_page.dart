import 'dart:async';

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import 'package:photos/ente_theme_data.dart';
import "package:photos/events/subscription_purchased_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/api/billing/billing_plan.dart';
import 'package:photos/models/api/billing/subscription.dart';
import 'package:photos/models/user_details.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/colors.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import 'package:photos/ui/common/web_page.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/payment/child_subscription_widget.dart';
import 'package:photos/ui/payment/payment_web_page.dart';
import 'package:photos/ui/payment/subscription_common_widgets.dart';
import 'package:photos/ui/payment/subscription_plan_widget.dart';
import "package:photos/ui/payment/view_add_on_widget.dart";
import "package:photos/ui/tabs/home_widget.dart";
import 'package:photos/utils/dialog_util.dart';
import "package:photos/utils/standalone/data.dart";
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

class StripeSubscriptionPage extends StatefulWidget {
  final bool isOnboarding;

  const StripeSubscriptionPage({
    this.isOnboarding = false,
    super.key,
  });

  @override
  State<StripeSubscriptionPage> createState() => _StripeSubscriptionPageState();
}

class _StripeSubscriptionPageState extends State<StripeSubscriptionPage> {
  late final _billingService = billingService;
  final _userService = UserService.instance;
  Subscription? _currentSubscription;
  late ProgressDialog _dialog;
  late UserDetails _userDetails;

  // indicates if user's subscription plan is still active
  late bool _hasActiveSubscription;
  bool _hideCurrentPlanSelection = false;
  List<BillingPlan> _plans = [];
  bool _hasLoadedData = false;
  bool _isLoading = false;
  bool _isStripeSubscriber = false;
  bool _showYearlyPlan = false;
  EnteColorScheme colorScheme = darkScheme;
  final Logger logger = Logger("StripeSubscriptionPage");

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
      showToast(
        context,
        AppLocalizations.of(context).failedToRefreshStripeSubscription,
      );
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
  Widget build(BuildContext context) {
    colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      appBar: widget.isOnboarding
          ? AppBar(
              scrolledUnderElevation: 0,
              elevation: 0,
              title: Hero(
                tag: "subscription",
                child: StepProgressIndicator(
                  totalSteps: 4,
                  currentStep: 4,
                  selectedColor: Theme.of(context).colorScheme.greenAlternative,
                  roundedEdges: const Radius.circular(10),
                  unselectedColor:
                      Theme.of(context).colorScheme.stepProgressUnselectedColor,
                ),
              ),
            )
          : AppBar(
              scrolledUnderElevation: 0,
              toolbarHeight: 48,
              leadingWidth: 48,
              leading: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back_outlined,
                ),
              ),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleBarTitleWidget(
                  title: widget.isOnboarding
                      ? AppLocalizations.of(context).selectYourPlan
                      : AppLocalizations.of(context).subscription,
                ),
                _isFreePlanUser() || !_hasLoadedData
                    ? const SizedBox.shrink()
                    : Text(
                        convertBytesToReadableFormat(
                          _userDetails.getTotalStorage(),
                        ),
                        style: textTheme.smallMuted,
                      ),
              ],
            ),
          ),
          Expanded(child: _getBody()),
        ],
      ),
    );
  }

  Widget _getBody() {
    if (!_isLoading) {
      _isLoading = true;
      _dialog = createProgressDialog(
        context,
        AppLocalizations.of(context).pleaseWait,
      );
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

    widgets.add(
      SubscriptionToggle(
        onToggle: (p0) {
          _showYearlyPlan = p0;
          _filterStripeForUI();
        },
      ),
    );

    widgets.addAll([
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _getStripePlanWidgets(),
      ),
      const Padding(padding: EdgeInsets.all(4)),
    ]);

    if (_currentSubscription != null) {
      widgets.add(
        ValidityWidget(
          currentSubscription: _currentSubscription,
          bonusData: _userDetails.bonusData,
        ),
      );
      widgets.add(const DividerWidget(dividerType: DividerType.bottomBar));
      widgets.add(const SizedBox(height: 20));
    } else {
      widgets.add(const DividerWidget(dividerType: DividerType.bottomBar));
      const SizedBox(height: 56);
    }

    if (_currentSubscription!.productID == freeProductID) {
      widgets.add(
        SubFaqWidget(isOnboarding: widget.isOnboarding),
      );
    }

    if (!widget.isOnboarding) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
          child: MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: AppLocalizations.of(context).manageFamily,
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
    }

    if (_currentSubscription!.productID != freeProductID) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
          child: MenuItemWidget(
            captionedTextWidget: const CaptionedTextWidget(
              title: "Manage payment method",
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

    // only active subscription can be renewed/canceled
    if (_hasActiveSubscription && _isStripeSubscriber) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: _stripeRenewOrCancelButton(),
        ),
      );
    }

    widgets.add(const SizedBox(height: 80));

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
          AppLocalizations.of(context).sorry,
          AppLocalizations.of(context)
              .contactToManageSubscription(provider: capitalizedWord),
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
            return WebPage(AppLocalizations.of(context).paymentDetails, url);
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
        ? AppLocalizations.of(context).renewSubscription
        : AppLocalizations.of(context).cancelSubscription;
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: title,
      ),
      alwaysShowSuccessState: false,
      surfaceExecutionStates: false,
      menuItemColor: colorScheme.fillFaint,
      trailingWidget: Icon(
        Icons.chevron_right_outlined,
        color: colorScheme.strokeBase,
      ),
      singleBorderRadius: 4,
      alignCaptionedTextToLeft: true,
      onTap: () async {
        bool confirmAction = false;
        if (isRenewCancelled) {
          final choice = await showChoiceDialog(
            context,
            title: title,
            body: AppLocalizations.of(context).areYouSureYouWantToRenew,
            firstButtonLabel: AppLocalizations.of(context).yesRenew,
          );
          confirmAction = choice!.action == ButtonAction.first;
        } else {
          final choice = await showChoiceDialog(
            context,
            title: title,
            body: AppLocalizations.of(context).areYouSureYouWantToCancel,
            firstButtonLabel: AppLocalizations.of(context).yesCancel,
            secondButtonLabel: AppLocalizations.of(context).no,
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
            ? AppLocalizations.of(context).failedToRenew
            : AppLocalizations.of(context).failedToCancel,
      );
    }
    await _dialog.hide();
    if (!isAutoRenewDisabled && mounted) {
      await showTextInputDialog(
        context,
        title: AppLocalizations.of(context).askCancelReason,
        submitButtonLabel: AppLocalizations.of(context).send,
        hintText: AppLocalizations.of(context).optionalAsShortAsYouLike,
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
        GestureDetector(
          onTap: () async {
            if (widget.isOnboarding && plan.id == freeProductID) {
              Bus.instance.fire(SubscriptionPurchasedEvent());
              // ignore: unawaited_futures
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return const HomeWidget();
                  },
                ),
                (route) => false,
              );
              unawaited(
                _billingService.verifySubscription(
                  freeProductID,
                  "",
                  paymentProvider: "ente",
                ),
              );
            } else {
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
                  AppLocalizations.of(context).sorry,
                  AppLocalizations.of(context).cancelOtherSubscription(
                    paymentProvider: _currentSubscription!.paymentProvider,
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
                  AppLocalizations.of(context).sorry,
                  AppLocalizations.of(context).youCannotDowngradeToThisPlan,
                );
                return;
              }
              String stripPurChaseAction = 'buy';
              if (_isStripeSubscriber && _hasActiveSubscription) {
                // confirm if user wants to change plan or not
                final result = await showChoiceDialog(
                  context,
                  title: AppLocalizations.of(context).confirmPlanChange,
                  body: AppLocalizations.of(context)
                      .areYouSureYouWantToChangeYourPlan,
                  firstButtonLabel: AppLocalizations.of(context).yes,
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
            }
          },
          child: SubscriptionPlanWidget(
            storage: plan.storage,
            price: plan.price,
            period: plan.period,
            isActive: isActive && !_hideCurrentPlanSelection,
            isPopular: _isPopularPlan(plan),
            isOnboarding: widget.isOnboarding,
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

  bool _isPopularPlan(BillingPlan plan) {
    return popularProductIDs.contains(plan.id);
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
      GestureDetector(
        onTap: () {
          if (_currentSubscription!.isFreePlan() && widget.isOnboarding) {
            Bus.instance.fire(SubscriptionPurchasedEvent());
            // ignore: unawaited_futures
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const HomeWidget();
                },
              ),
              (route) => false,
            );
            unawaited(
              _billingService.verifySubscription(
                freeProductID,
                "",
                paymentProvider: "ente",
              ),
            );
          }
        },
        child: SubscriptionPlanWidget(
          storage: _currentSubscription!.storage,
          price: _currentSubscription!.price,
          period: _currentSubscription!.period,
          isActive: _currentSubscription!.isValid(),
          isOnboarding: widget.isOnboarding,
        ),
      ),
    );
  }
}
