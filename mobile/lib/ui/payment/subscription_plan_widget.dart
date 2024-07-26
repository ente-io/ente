import 'package:flutter/material.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/utils/data_util.dart';

class SubscriptionPlanWidget extends StatelessWidget {
  const SubscriptionPlanWidget({
    super.key,
    required this.storage,
    required this.price,
    required this.period,
    this.isActive = false,
  });

  final int storage;
  final String price;
  final String period;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final numAndUnit = convertBytesToNumberAndUnit(storage);
    final String storageValue = numAndUnit.$1.toString();
    final String storageUnit = numAndUnit.$2;
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.subscriptionPlanWidgetColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.subscriptionPlanWidgetStoke,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: storageValue,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: getEnteColorScheme(context).textBase,
                    ),
                  ),
                  WidgetSpan(
                    child: Transform.translate(
                      offset: const Offset(2, -16),
                      child: Text(
                        storageUnit,
                        style: getEnteTextTheme(context).h3Muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _Price(price: price, period: period),
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
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    if (price.isEmpty) {
      return Text(
        "Free",
        style: textTheme.largeBold,
      );
    }
    if (period == "month") {
      return RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: price,
              style: textTheme.largeBold,
            ),
            TextSpan(text: ' / ' 'month', style: textTheme.largeBold),
          ],
        ),
      );
    } else if (period == "year") {
      final currencySymbol = price[0];
      final priceWithoutCurrency = price.substring(1);
      final priceDouble = double.parse(priceWithoutCurrency);
      final pricePerMonth = priceDouble / 12;
      final pricePerMonthString = pricePerMonth.toStringAsFixed(2);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: currencySymbol + pricePerMonthString,
                  style: textTheme.largeBold,
                ),
                TextSpan(
                  text: ' / ' 'month',
                  style: textTheme.largeBold,
                ),
              ],
            ),
          ),
          Text(
            price + " / " + "yr",
            style: textTheme.bodyFaint,
          ),
        ],
      );
    } else {
      assert(false, "Invalid period: $period");
      return const Text("");
    }
  }
}
