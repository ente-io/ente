import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:flutter/scheduler.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/utils/standalone/data.dart';

class SubscriptionPlanWidget extends StatefulWidget {
  const SubscriptionPlanWidget({
    super.key,
    required this.storage,
    required this.price,
    required this.period,
    required this.isOnboarding,
    this.isActive = false,
    this.isPopular = false,
  });

  final int storage;
  final String price;
  final String period;
  final bool isActive;
  final bool isPopular;
  final bool isOnboarding;

  @override
  State<SubscriptionPlanWidget> createState() => _SubscriptionPlanWidgetState();
}

class _SubscriptionPlanWidgetState extends State<SubscriptionPlanWidget> {
  late final PlatformDispatcher _platformDispatcher;

  @override
  void initState() {
    super.initState();
    _platformDispatcher = SchedulerBinding.instance.platformDispatcher;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _platformDispatcher.platformBrightness;
    final numAndUnit = convertBytesToNumberAndUnit(widget.storage);
    final String storageValue = numAndUnit.$1.toString();
    final String storageUnit = numAndUnit.$2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundElevated2Light,
          borderRadius: BorderRadius.circular(8),
          border: widget.isActive
              ? Border.all(
                  color: getEnteColorScheme(context).primary700,
                  width: brightness == Brightness.dark ? 1.5 : 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            widget.isActive && !widget.isOnboarding
                ? Positioned(
                    top: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                      ),
                      child: Image.asset(
                        "assets/active_subscription.png",
                      ),
                    ),
                  )
                : widget.isPopular
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                        ),
                        child: Image.asset(
                          "assets/popular_subscription.png",
                        ),
                      )
                    : const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: storageValue,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            color: textBaseLight,
                          ),
                        ),
                        WidgetSpan(
                          child: Transform.translate(
                            offset: const Offset(2, -16),
                            child: Text(
                              storageUnit,
                              style: getEnteTextTheme(context).h3.copyWith(
                                    color: textMutedLight,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Price(price: widget.price, period: widget.period),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Price extends StatelessWidget {
  final String price;
  final String period;
  const _Price({required this.price, required this.period});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    if (price.isEmpty) {
      return Text(
        "Free",
        style: textTheme.largeBold.copyWith(color: textBaseLight),
      );
    }
    if (period == "month") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            price + ' / ' + AppLocalizations.of(context).month,
            style: textTheme.largeBold.copyWith(color: textBaseLight),
          )
              .animate(delay: const Duration(milliseconds: 100))
              .fadeIn(duration: const Duration(milliseconds: 250)),
        ],
      );
    } else if (period == "year") {
      final currencySymbol = price[0];
      final priceWithoutCurrency = price.substring(1);
      final priceDouble = double.parse(priceWithoutCurrency);
      final pricePerMonth = priceDouble / 12;
      String pricePerMonthString = pricePerMonth.toStringAsFixed(2);

      if (pricePerMonthString.endsWith(".00")) {
        pricePerMonthString =
            pricePerMonthString.substring(0, pricePerMonthString.length - 3);
      }

      final bool isPlayStore = updateService.isPlayStoreFlavor();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isPlayStore)
            Text(
              currencySymbol +
                  pricePerMonthString +
                  ' / ' +
                  AppLocalizations.of(context).month,
              style: textTheme.largeBold.copyWith(color: textBaseLight),
            ),
          if (isPlayStore)
            Text(
              price + " / " + AppLocalizations.of(context).yearShort,
              style: textTheme.small.copyWith(color: textFaintLight),
            ),
          if (!isPlayStore)
            Text(
              currencySymbol +
                  pricePerMonthString +
                  ' / ' +
                  AppLocalizations.of(context).month,
              style: textTheme.largeBold.copyWith(color: textBaseLight),
            ),
          if (!isPlayStore)
            Text(
              price + " / " + AppLocalizations.of(context).yearShort,
              style: textTheme.small.copyWith(color: textFaintLight),
            ),
        ],
      )
          .animate(delay: const Duration(milliseconds: 100))
          .fadeIn(duration: const Duration(milliseconds: 250));
    } else {
      assert(false, "Invalid period: $period");
      return const Text("");
    }
  }
}
