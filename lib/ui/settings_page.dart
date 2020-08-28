import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/date_time_util.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            UsageWidget(),
          ],
        ),
      ),
    );
  }
}

class UsageWidget extends StatefulWidget {
  UsageWidget({Key key}) : super(key: key);

  @override
  UsageWidgetState createState() => UsageWidgetState();
}

class UsageWidgetState extends State<UsageWidget> {
  double _usageInGBs;
  @override
  void initState() {
    _getUsage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Expanded(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(4)),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "BILLING",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).accentColor,
                ),
              ),
            ),
            Padding(padding: EdgeInsets.all(8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total data backed up"),
                _usageInGBs == null
                    ? loadWidget
                    : Text(
                        _usageInGBs.toString() + " GB",
                      ),
              ],
            ),
            Padding(padding: EdgeInsets.all(4)),
            Divider(height: 10),
            Padding(padding: EdgeInsets.all(4)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Tentative bill for " + getMonth(DateTime.now())),
                _usageInGBs == null ? loadWidget : _getCost(_usageInGBs),
              ],
            )
          ],
        ),
      ),
    );
  }

  Text _getCost(double usageInGBs) {
    return Text("\$" + (usageInGBs * 0.1).toStringAsFixed(2));
  }

  void _getUsage() {
    Dio().get(
      Configuration.instance.getHttpEndpoint() + "/billing/usage",
      queryParameters: {
        "startTime": 0,
        "endTime": DateTime.now().microsecondsSinceEpoch,
        "token": Configuration.instance.getToken(),
      },
    ).catchError((e) async {
      Logger("Settings").severe(e);
    }).then((response) async {
      if (response != null && response.statusCode == 200) {
        final usageInBytes = response.data["usage"];
        if (mounted) {
          setState(() {
            _usageInGBs = double.parse(
                (usageInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2));
          });
        }
      }
    });
  }
}
