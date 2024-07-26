import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
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
    return Row(
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
    if (price.isEmpty) {
      return Text(S.of(context).freeTrial);
    }
    if (period == "month") {
      return RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: price,
              style: TextStyle(
                fontSize: 20,
                color: colorScheme.textBase,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: ' / ' 'month',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.textBase,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                  style: TextStyle(
                    fontSize: 20,
                    color: colorScheme.textBase,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' / ' 'month',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.textBase,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price + " / " + "year",
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.textFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      assert(false, "Invalid period: $period");
      return const Text("");
    }
  }
}
