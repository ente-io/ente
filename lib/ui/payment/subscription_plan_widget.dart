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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 36, 10),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  color: Color(0xDFFFFFFF),
                  child: Container(
                    width: 100,
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                    child: Column(
                      children: [
                        Text(
                          convertBytesToReadableFormat(storage),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).cardColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Text(price + (period.isNotEmpty ? " per " + period : "")),
              Expanded(child: Container()),
              isActive
                  ? Expanded(
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).buttonColor,
                ),
              )
                  : Container(),
            ],
          ),
          Divider(
            height: 1,
          ),
        ],
      ),
    );
  }
}
