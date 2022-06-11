import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/utils/data_util.dart';

class SubscriptionPlanWidget extends StatelessWidget {
  const SubscriptionPlanWidget({
    Key key,
    @required this.storage,
    @required this.price,
    @required this.period,
    this.isActive = false,
  }) : super(key: key);

  final int storage;
  final String price;
  final String period;
  final bool isActive;

  String _displayPrice() {
    var result = price + (period.isNotEmpty ? " / " + period : "");
    return result.isNotEmpty ? result : "Trial plan";
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = isActive ? Colors.white : Colors.black;
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.onPrimary,
      padding: EdgeInsets.symmetric(horizontal: isActive ? 8 : 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color:
              isActive ? Color(0xFF22763F) : Color.fromRGBO(240, 240, 240, 1.0),
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [
                    Color(0xFF2CD267),
                    Color(0xFF1DB954),
                  ],
                )
              : null,
        ),
        // color: Colors.yellow,
        padding:
            EdgeInsets.symmetric(horizontal: isActive ? 22 : 20, vertical: 18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  convertBytesToReadableFormat(storage),
                  style: Theme.of(context)
                      .textTheme
                      .headline6
                      .copyWith(color: textColor),
                ),
                Text(
                  _displayPrice(),
                  style: Theme.of(context).textTheme.headline6.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.normal,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
