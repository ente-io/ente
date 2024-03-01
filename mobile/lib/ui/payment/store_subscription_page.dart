import 'dart:async';
import 'dart:io';

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/billing_plan.dart';
import 'package:photos/models/subscription.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/billing_service.dart';
import "package:photos/services/update_service.dart";
import 'package:photos/services/user_service.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import 'package:photos/ui/payment/child_subscription_widget.dart';
import 'package:photos/ui/payment/skip_subscription_widget.dart';
import 'package:photos/ui/payment/subscription_common_widgets.dart';
import 'package:photos/ui/payment/subscription_plan_widget.dart';
import "package:photos/ui/payment/view_add_on_widget.dart";
import "package:photos/utils/data_util.dart";
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher_string.dart';

class StoreSubscriptionPage extends StatefulWidget {
  final bool isOnboarding;

  const StoreSubscriptionPage({
    this.isOnboarding = false,
    Key? key,
  }) : super(key: key);

  @override
  State<StoreSubscriptionPage> createState() => _StoreSubscriptionPageState();
}

class _StoreSubscriptionPageState extends State<StoreSubscriptionPage> {
  final _logger = Logger("SubscriptionPage");
  final _billingService = BillingService.instance;
  final _userService = UserService.instance;
  Subscription? _currentSubscription;
  late StreamSubscription _purchaseUpdateSubscription;
  late ProgressDialog _dialog;
  late UserDetails _userDetails;
  late bool _hasActiveSubscription;
  bool _hideCurrentPlanSelection = false;
  late FreePlan _freePlan;
  late List<BillingPlan> _plans;
  bool _hasLoadedData = false;
  bool _isLoading = false;
  late bool _isActiveStripeSubscriber;
  EnteColorScheme colorScheme = darkScheme;

  // hasYearlyPlans is used to check if there are yearly plans for given store
  bool hasYearlyPlans = false;

  // _showYearlyPlan is used to determine if we should show the yearly plans
  bool showYearlyPlan = false;

  @override
  void initState() {
    _billingService.setIsOnSubscriptionPage(true);
    _setupPurchaseUpdateStreamListener();
    super.initState();
  }

  void _setupPurchaseUpdateStreamListener() {
    _purchaseUpdateSubscription =
        InAppPurchase.instance.purchaseStream.listen((purchases) async {
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
            await InAppPurchase.instance.completePurchase(purchase);
            String text = S.of(context).thankYouForSubscribing;
            if (!widget.isOnboarding) {
              final isUpgrade = _hasActiveSubscription &&
                  newSubscription.storage > _currentSubscription!.storage;
              final isDowngrade = _hasActiveSubscription &&
                  newSubscription.storage < _currentSubscription!.storage;
              if (isUpgrade) {
                text = S.of(context).yourPlanWasSuccessfullyUpgraded;
              } else if (isDowngrade) {
                text = S.of(context).yourPlanWasSuccessfullyDowngraded;
              }
            }
            showShortToast(context, text);
            _currentSubscription = newSubscription;
            _hasActiveSubscription = _currentSubscription!.isValid();
            setState(() {});
            await _dialog.hide();
            Bus.instance.fire(SubscriptionPurchasedEvent());
            if (widget.isOnboarding) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } on SubscriptionAlreadyClaimedError catch (e) {
            _logger.warning("subscription is already claimed ", e);
            await _dialog.hide();
            final String title = Platform.isAndroid
                ? S.of(context).playstoreSubscription
                : S.of(context).appstoreSubscription;
            final String id = Platform.isAndroid
                ? S.of(context).googlePlayId
                : S.of(context).appleId;
            final String message = S.of(context).subAlreadyLinkedErrMessage(id);
            // ignore: unawaited_futures
            showErrorDialog(context, title, message);
            return;
          } catch (e) {
            _logger.warning("Could not complete payment ", e);
            await _dialog.hide();
            // ignore: unawaited_futures
            showErrorDialog(
              context,
              S.of(context).paymentFailed,
              S.of(context).paymentFailedTalkToProvider(
                    Platform.isAndroid ? "PlayStore" : "AppStore",
                  ),
            );
            return;
          }
        } else if (Platform.isIOS && purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
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
    colorScheme = getEnteColorScheme(context);
    if (!_isLoading) {
      _isLoading = true;
      _fetchSubData();
    }
    _dialog = createProgressDialog(context, S.of(context).pleaseWait);
    final appBar = AppBar(
      title: widget.isOnboarding
          ? null
          : Text("${S.of(context).subscription}${kDebugMode ? ' Store' : ''}"),
    );
    return Scaffold(
      appBar: appBar,
      body: _getBody(),
    );
  }

  bool _isFreePlanUser() {
    return _currentSubscription != null &&
        freeProductID == _currentSubscription!.productID;
  }

  Future<void> _fetchSubData() async {
    // ignore: unawaited_futures
    _userService.getUserDetailsV2(memoryCount: false).then((userDetails) async {
      _userDetails = userDetails;
      _currentSubscription = userDetails.subscription;

      _hasActiveSubscription = _currentSubscription!.isValid();
      _hideCurrentPlanSelection =
          _currentSubscription?.attributes?.isCancelled ?? false;
      showYearlyPlan = _currentSubscription!.isYearlyPlan();
      final billingPlans = await _billingService.getBillingPlans();
      _isActiveStripeSubscriber =
          _currentSubscription!.paymentProvider == stripe &&
              _currentSubscription!.isValid();
      _plans = billingPlans.plans.where((plan) {
        final productID = _isActiveStripeSubscriber
            ? plan.stripeID
            : Platform.isAndroid
                ? plan.androidID
                : plan.iosID;
        return productID.isNotEmpty;
      }).toList();
      hasYearlyPlans = _plans.any((plan) => plan.period == 'year');
      if (showYearlyPlan && hasYearlyPlans) {
        _plans = _plans.where((plan) => plan.period == 'year').toList();
      } else {
        _plans = _plans.where((plan) => plan.period != 'year').toList();
      }
      _freePlan = billingPlans.freePlan;
      _hasLoadedData = true;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _getBody() {
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
        children: _isActiveStripeSubscriber
            ? _getStripePlanWidgets()
            : _getMobilePlanWidgets(),
      ),
      const Padding(padding: EdgeInsets.all(8)),
    ]);

    if (hasYearlyPlans) {
      widgets.add(_showSubscriptionToggle());
    }

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

    if (_hasActiveSubscription &&
        _currentSubscription!.productID != freeProductID) {
      if (_isActiveStripeSubscriber) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Text(
              S.of(context).visitWebToManage,
              style: getEnteTextTheme(context).small.copyWith(
                    color: colorScheme.textMuted,
                  ),
            ),
          ),
        );
      } else {
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
                _onPlatformRestrictedPaymentDetailsClick();
              },
            ),
          ),
        );
      }
    }
    if (!widget.isOnboarding) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: _isFreePlanUser()
                  ? S.of(context).familyPlans
                  : S.of(context).manageFamily,
            ),
            menuItemColor: colorScheme.fillFaint,
            trailingWidget: Icon(
              Icons.chevron_right_outlined,
              color: colorScheme.strokeBase,
            ),
            singleBorderRadius: 4,
            alignCaptionedTextToLeft: true,
            onTap: () async {
              unawaited(
                _billingService.launchFamilyPortal(context, _userDetails),
              );
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

  void _onPlatformRestrictedPaymentDetailsClick() {
    final String paymentProvider = _currentSubscription!.paymentProvider;
    if (paymentProvider == appStore && !Platform.isAndroid) {
      launchUrlString("https://apps.apple.com/account/billing");
    } else if (paymentProvider == playStore && Platform.isAndroid) {
      launchUrlString(
        "https://play.google.com/store/account/subscriptions?sku=" +
            _currentSubscription!.productID +
            "&package=io.ente.photos",
      );
    } else if (paymentProvider == stripe) {
      showErrorDialog(
        context,
        S.of(context).sorry,
        S.of(context).visitWebToManage,
      );
    } else {
      final String capitalizedWord = paymentProvider.isNotEmpty
          ? '${paymentProvider[0].toUpperCase()}${paymentProvider.substring(1).toLowerCase()}'
          : '';
      showErrorDialog(
        context,
        S.of(context).sorry,
        S.of(context).contactToManageSubscription(capitalizedWord),
      );
    }
  }

  Future<void> _filterStorePlansForUi() async {
    final billingPlans = await _billingService.getBillingPlans();
    _plans = billingPlans.plans.where((plan) {
      final productID = _isActiveStripeSubscriber
          ? plan.stripeID
          : Platform.isAndroid
              ? plan.androidID
              : plan.iosID;
      return productID.isNotEmpty;
    }).toList();
    hasYearlyPlans = _plans.any((plan) => plan.period == 'year');
    if (showYearlyPlan) {
      _plans = _plans.where((plan) => plan.period == 'year').toList();
    } else {
      _plans = _plans.where((plan) => plan.period != 'year').toList();
    }
    setState(() {});
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
                planText(S.of(context).monthly, showYearlyPlan),
                Switch(
                  value: showYearlyPlan,
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.white,
                  activeTrackColor: getEnteColorScheme(context).strokeMuted,
                  onChanged: (value) async {
                    showYearlyPlan = value;
                    await _filterStorePlansForUi();
                  },
                ),
                planText(S.of(context).yearly, !showYearlyPlan),
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
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              if (isActive) {
                return;
              }
              // ignore: unawaited_futures
              showErrorDialog(
                context,
                S.of(context).sorry,
                S.of(context).visitWebToManage,
              );
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

  List<Widget> _getMobilePlanWidgets() {
    bool foundActivePlan = false;
    final List<Widget> planWidgets = [];
    if (_hasActiveSubscription &&
        _currentSubscription!.productID == freeProductID) {
      foundActivePlan = true;
      planWidgets.add(
        SubscriptionPlanWidget(
          storage: _freePlan.storage,
          price: S.of(context).freeTrial,
          period: "",
          isActive: true,
        ),
      );
    }
    for (final plan in _plans) {
      final productID = Platform.isAndroid ? plan.androidID : plan.iosID;
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
              final int addOnBonus =
                  _userDetails.bonusData?.totalAddOnBonus() ?? 0;
              if (_userDetails.getFamilyOrPersonalUsage() >
                  (plan.storage + addOnBonus)) {
                _logger.warning(
                  " familyUsage ${convertBytesToReadableFormat(_userDetails.getFamilyOrPersonalUsage())}"
                  " plan storage ${convertBytesToReadableFormat(plan.storage)} "
                  "addOnBonus ${convertBytesToReadableFormat(addOnBonus)},"
                  "overshooting by ${convertBytesToReadableFormat(_userDetails.getFamilyOrPersonalUsage() - (plan.storage + addOnBonus))}",
                );
                // ignore: unawaited_futures
                showErrorDialog(
                  context,
                  S.of(context).sorry,
                  S.of(context).youCannotDowngradeToThisPlan,
                );
                return;
              }
              await _dialog.show();
              final ProductDetailsResponse response =
                  await InAppPurchase.instance.queryProductDetails({productID});
              if (response.notFoundIDs.isNotEmpty) {
                final errMsg = "Could not find products: " +
                    response.notFoundIDs.toString();
                _logger.severe(errMsg);
                await _dialog.hide();
                await showGenericErrorDialog(
                  context: context,
                  error: Exception(errMsg),
                );
                return;
              }
              final isCrossGradingOnAndroid = Platform.isAndroid &&
                  _hasActiveSubscription &&
                  _currentSubscription!.productID != freeProductID &&
                  _currentSubscription!.productID != plan.androidID;
              if (isCrossGradingOnAndroid) {
                await _dialog.hide();
                // ignore: unawaited_futures
                showErrorDialog(
                  context,
                  S.of(context).couldNotUpdateSubscription,
                  S.of(context).pleaseContactSupportAndWeWillBeHappyToHelp,
                );
                return;
              } else {
                await InAppPurchase.instance.buyNonConsumable(
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
    if (!foundActivePlan && _hasActiveSubscription) {
      _addCurrentPlanWidget(planWidgets);
    }
    return planWidgets;
  }

  void _addCurrentPlanWidget(List<Widget> planWidgets) {
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
