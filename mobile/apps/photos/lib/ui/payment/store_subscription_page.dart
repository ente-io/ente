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
import 'package:photos/models/api/billing/billing_plan.dart';
import 'package:photos/models/api/billing/subscription.dart';
import 'package:photos/models/user_details.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/common/progress_dialog.dart';
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/payment/child_subscription_widget.dart';
import 'package:photos/ui/payment/subscription_common_widgets.dart';
import 'package:photos/ui/payment/subscription_plan_widget.dart';
import "package:photos/ui/payment/view_add_on_widget.dart";
import "package:photos/ui/tabs/home_widget.dart";
import 'package:photos/utils/dialog_util.dart';
import "package:photos/utils/standalone/data.dart";
import 'package:url_launcher/url_launcher_string.dart';

class StoreSubscriptionPage extends StatefulWidget {
  final bool isOnboarding;

  const StoreSubscriptionPage({
    this.isOnboarding = false,
    super.key,
  });

  @override
  State<StoreSubscriptionPage> createState() => _StoreSubscriptionPageState();
}

class _StoreSubscriptionPageState extends State<StoreSubscriptionPage> {
  final _logger = Logger("SubscriptionPage");
  late final _billingService = billingService;
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
    super.initState();
    _billingService.setIsOnSubscriptionPage(true);
    _setupPurchaseUpdateStreamListener();
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
            String text = AppLocalizations.of(context).thankYouForSubscribing;
            if (!widget.isOnboarding) {
              final isUpgrade = _hasActiveSubscription &&
                  newSubscription.storage > _currentSubscription!.storage;
              final isDowngrade = _hasActiveSubscription &&
                  newSubscription.storage < _currentSubscription!.storage;
              if (isUpgrade) {
                text = AppLocalizations.of(context)
                    .yourPlanWasSuccessfullyUpgraded;
              } else if (isDowngrade) {
                text = AppLocalizations.of(context)
                    .yourPlanWasSuccessfullyDowngraded;
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
                ? AppLocalizations.of(context).playstoreSubscription
                : AppLocalizations.of(context).appstoreSubscription;
            final String id = Platform.isAndroid
                ? AppLocalizations.of(context).googlePlayId
                : AppLocalizations.of(context).appleId;
            final String message =
                AppLocalizations.of(context).subAlreadyLinkedErrMessage(id: id);
            // ignore: unawaited_futures
            showErrorDialog(context, title, message);
            return;
          } catch (e) {
            _logger.warning("Could not complete payment ", e);
            await _dialog.hide();
            // ignore: unawaited_futures
            showErrorDialog(
              context,
              AppLocalizations.of(context).paymentFailed,
              AppLocalizations.of(context).paymentFailedTalkToProvider(
                providerName: Platform.isAndroid ? "PlayStore" : "AppStore",
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
    final textTheme = getEnteTextTheme(context);
    colorScheme = getEnteColorScheme(context);
    if (!_isLoading) {
      _isLoading = true;
      _fetchSubData();
    }
    _dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).pleaseWait,
      isDismissible: true,
    );
    return Scaffold(
      appBar: AppBar(),
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
                      : "${AppLocalizations.of(context).subscription}${kDebugMode ? ' Store' : ''}",
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

  bool _isFreePlanUser() {
    return _currentSubscription != null &&
        freeProductID == _currentSubscription!.productID;
  }

  Future<void> _fetchSubData() async {
    try {
      final userDetails =
          await _userService.getUserDetailsV2(memoryCount: false);
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
    } catch (e, s) {
      _logger.severe("Error fetching subscription data", e, s);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

    if (hasYearlyPlans) {
      widgets.add(
        SubscriptionToggle(
          onToggle: (p0) {
            showYearlyPlan = p0;
            _filterStorePlansForUi();
          },
        ),
      );
    }

    widgets.addAll([
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _isActiveStripeSubscriber
            ? _getStripePlanWidgets()
            : _getMobilePlanWidgets(),
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

    if (_hasActiveSubscription &&
        _currentSubscription!.productID != freeProductID) {
      if (_isActiveStripeSubscriber) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Text(
              AppLocalizations.of(context).visitWebToManage,
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
                _onPlatformRestrictedPaymentDetailsClick();
              },
            ),
          ),
        );
      }
    }

    widgets.add(
      SubFaqWidget(isOnboarding: widget.isOnboarding),
    );

    if (!widget.isOnboarding) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
          child: MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: _isFreePlanUser()
                  ? AppLocalizations.of(context).familyPlans
                  : AppLocalizations.of(context).manageFamily,
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
    }

    widgets.add(const SizedBox(height: 80));

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
        AppLocalizations.of(context).sorry,
        AppLocalizations.of(context).visitWebToManage,
      );
    } else {
      final String capitalizedWord = paymentProvider.isNotEmpty
          ? '${paymentProvider[0].toUpperCase()}${paymentProvider.substring(1).toLowerCase()}'
          : '';
      showErrorDialog(
        context,
        AppLocalizations.of(context).sorry,
        AppLocalizations.of(context)
            .contactToManageSubscription(provider: capitalizedWord),
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
              // ignore: unawaited_futures
              showErrorDialog(
                context,
                AppLocalizations.of(context).sorry,
                AppLocalizations.of(context).visitWebToManage,
              );
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

  List<Widget> _getMobilePlanWidgets() {
    bool foundActivePlan = false;
    final List<Widget> planWidgets = [];
    if (_hasActiveSubscription &&
        _currentSubscription!.productID == freeProductID) {
      foundActivePlan = true;
      planWidgets.add(
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
            storage: _freePlan.storage,
            price: "",
            period: AppLocalizations.of(context).freeTrial,
            isActive: true,
            isOnboarding: widget.isOnboarding,
          ),
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
        GestureDetector(
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
                AppLocalizations.of(context).sorry,
                AppLocalizations.of(context).youCannotDowngradeToThisPlan,
              );
              return;
            }
            await _dialog.show();
            final ProductDetailsResponse response =
                await InAppPurchase.instance.queryProductDetails({productID});
            if (response.notFoundIDs.isNotEmpty) {
              final errMsg =
                  "Could not find products: " + response.notFoundIDs.toString();
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
                AppLocalizations.of(context).couldNotUpdateSubscription,
                AppLocalizations.of(context)
                    .pleaseContactSupportAndWeWillBeHappyToHelp,
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

  void _addCurrentPlanWidget(List<Widget> planWidgets) {
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
          if (_currentSubscription!.isFreePlan() & widget.isOnboarding) {
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
          isActive: true,
          isOnboarding: widget.isOnboarding,
        ),
      ),
    );
  }

  bool _isPopularPlan(BillingPlan plan) {
    return popularProductIDs.contains(plan.id);
  }
}
