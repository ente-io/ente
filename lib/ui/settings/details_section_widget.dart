import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:pie_chart/pie_chart.dart';

class DetailsSectionWidget extends StatefulWidget {
  DetailsSectionWidget({Key key}) : super(key: key);

  @override
  _DetailsSectionWidgetState createState() => _DetailsSectionWidgetState();
}

class _DetailsSectionWidgetState extends State<DetailsSectionWidget> {
  UserDetails _userDetails;

  @override
  void initState() {
    super.initState();
    UserService.instance.getUserDetails().then((details) {
      setState(() {
        _userDetails = details;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: _userDetails == null ? loadWidget : getContainer(),
    );
  }

  Container getContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withBlue(210).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
      margin: EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () {
              showToast(formatBytes(
                      _userDetails.subscription.storage - _userDetails.usage) +
                  " / " +
                  convertBytesToReadableFormat(
                      _userDetails.subscription.storage) +
                  " free");
            },
            child: PieChart(
              dataMap: {
                "used": _userDetails.usage.toDouble(),
                "free": max(
                    _userDetails.subscription.storage.toDouble() -
                        _userDetails.usage.toDouble(),
                    0),
              },
              colorList: const [
                Colors.redAccent,
                Color.fromRGBO(50, 194, 100, 1.0),
              ],
              legendOptions: LegendOptions(
                showLegends: false,
              ),
              chartValuesOptions: ChartValuesOptions(
                showChartValues: false,
                showChartValueBackground: false,
              ),
              chartRadius: 80,
              ringStrokeWidth: 4,
              chartType: ChartType.ring,
              centerText:
                  convertBytesToReadableFormat(_userDetails.usage) + "\nused",
              centerTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              initialAngleInDegree: 270,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userDetails.email,
                style: TextStyle(
                  // color: Theme.of(context).buttonColor,
                  fontSize: 16,
                ),
              ),
              Padding(padding: EdgeInsets.all(8)),
              Text(
                _userDetails.fileCount.toString() + " memories preserved",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              Padding(padding: EdgeInsets.all(4)),
              Text(
                _userDetails.sharedCollectionsCount.toString() +
                    " albums shared",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
