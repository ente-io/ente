import 'dart:async';
import 'dart:io';

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/billing_plan.dart';
import 'package:photos/models/subscription.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/billing_service.dart';
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
            String text = "Thank you for subscribing!";
            if (!widget.isOnboarding) {
              final isUpgrade = _hasActiveSubscription &&
                  newSubscription.storage > _currentSubscription!.storage;
              final isDowngrade = _hasActiveSubscription &&
                  newSubscription.storage < _currentSubscription!.storage;
              if (isUpgrade) {
                text = "Your plan was successfully upgraded";
              } else if (isDowngrade) {
                text = "Your plan was successfully downgraded";
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
            final String title = "${Platform.isAndroid ? "Play" : "App"}"
                "Store subscription";
            final String id =
                Platform.isAndroid ? "Google Play ID" : "Apple ID";
            final String message = '''Your $id is already linked to another
             ente account.\nIf you would like to use your $id with this 
             account, please contact our support''';
            showErrorDialog(context, title, message);
            return;
          } catch (e) {
            _logger.warning("Could not complete payment ", e);
            await _dialog.hide();
            showErrorDialog(
              context,
              "Payment failed",
              "Please talk to " +
                  (Platform.isAndroid ? "PlayStore" : "AppStore") +
                  " support if you were charged",
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
    _dialog = createProgressDialog(context, "Please wait...");
    final appBar = AppBar(
      title: widget.isOnboarding
          ? null
          : const Text("Subscription${kDebugMode ? ' Store' : ''}"),
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
    _userService.getUserDetailsV2(memoryCount: false).then((userDetails) async {
      _userDetails = userDetails;
      _currentSubscription = userDetails.subscription;
      _hasActiveSubscription = _currentSubscription!.isValid();
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

    if (_hasActiveSubscription &&
        _currentSubscription!.productID != freeProductID) {
      if (_isActiveStripeSubscriber) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Text(
              "Visit web.ente.io to manage your subscription",
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          child: MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: _isFreePlanUser() ? "Family Plans" : "Manage Family",
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
        "Sorry",
        "Visit web.ente.io to manage your subscription",
      );
    } else {
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
                planText("Monthly", showYearlyPlan),
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
                planText("Yearly", !showYearlyPlan),
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
              showErrorDialog(
                context,
                "Sorry",
                "Please visit web.ente.io to manage your subscription",
              );
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

  List<Widget> _getMobilePlanWidgets() {
    bool foundActivePlan = false;
    final List<Widget> planWidgets = [];
    if (_hasActiveSubscription &&
        _currentSubscription!.productID == freeProductID) {
      foundActivePlan = true;
      planWidgets.add(
        SubscriptionPlanWidget(
          storage: _freePlan.storage,
          price: "Free trial",
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
              if (_userDetails.getFamilyOrPersonalUsage() > plan.storage) {
                showErrorDialog(
                  context,
                  "Sorry",
                  "You cannot downgrade to this plan",
                );
                return;
              }
              await _dialog.show();
              final ProductDetailsResponse response =
                  await InAppPurchase.instance.queryProductDetails({productID});
              if (response.notFoundIDs.isNotEmpty) {
                _logger.severe(
                  "Could not find products: " + response.notFoundIDs.toString(),
                );
                await _dialog.hide();
                showGenericErrorDialog(context: context);
                return;
              }
              final isCrossGradingOnAndroid = Platform.isAndroid &&
                  _hasActiveSubscription &&
                  _currentSubscription!.productID != freeProductID &&
                  _currentSubscription!.productID != plan.androidID;
              if (isCrossGradingOnAndroid) {
                await _dialog.hide();
                showErrorDialog(
                  context,
                  "Could not update subscription",
                  "Please contact support@ente.io and we will be happy to help!",
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
