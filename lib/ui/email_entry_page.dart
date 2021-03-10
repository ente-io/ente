import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/billing_plan.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/web_page.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';

class EmailEntryPage extends StatefulWidget {
  EmailEntryPage({Key key}) : super(key: key);

  @override
  _EmailEntryPageState createState() => _EmailEntryPageState();
}

class _EmailEntryPageState extends State<EmailEntryPage> {
  final _config = Configuration.instance;
  String _email;
  String _name;

  @override
  void initState() {
    _email = _config.getEmail();
    _name = _config.getName();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text(
        "sign up",
        style: TextStyle(
          fontSize: 18,
        ),
      ),
    );
    return Scaffold(
      appBar: appBar,
      body: _getBody(appBar.preferredSize.height),
    );
  }

  Widget _getBody(final appBarSize) {
    final pageSize = MediaQuery.of(context).size.height;
    final notifySize = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      child: Container(
        height: pageSize - (appBarSize + notifySize),
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: EdgeInsets.all(60),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'name',
                  hintStyle: TextStyle(
                    color: Colors.white30,
                  ),
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  setState(() {
                    _name = value;
                  });
                },
                autocorrect: false,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                initialValue: _name,
              ),
            ),
            Padding(padding: EdgeInsets.all(8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'email',
                  hintStyle: TextStyle(
                    color: Colors.white30,
                  ),
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  setState(() {
                    _email = value;
                  });
                },
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                initialValue: _email,
              ),
            ),
            Padding(padding: EdgeInsets.all(8)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "by clicking sign up, I agree to the ",
                    ),
                    TextSpan(
                      text: "terms of service",
                      style: TextStyle(
                        color: Colors.blue,
                        fontFamily: 'Ubuntu',
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) {
                                return WebPage(
                                    "terms", "https://ente.io/terms");
                              },
                            ),
                          );
                        },
                    ),
                    TextSpan(text: " and "),
                    TextSpan(
                      text: "privacy policy",
                      style: TextStyle(
                        color: Colors.blue,
                        fontFamily: 'Ubuntu',
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) {
                                return WebPage(
                                    "privacy", "https://ente.io/privacy");
                              },
                            ),
                          );
                        },
                    ),
                  ],
                  style: TextStyle(
                    height: 1.25,
                    fontSize: 12,
                    fontFamily: 'Ubuntu',
                    color: Colors.white70,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Container(
              width: double.infinity,
              height: 64,
              padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
              child: button(
                "sign up",
                onPressed: _email != null &&
                        _email.isNotEmpty &&
                        _name != null &&
                        _name.isNotEmpty
                    ? () {
                        if (!isValidEmail(_email)) {
                          showErrorDialog(context, "invalid email address",
                              "please enter a valid email address.");
                          return;
                        }
                        _config.setEmail(_email);
                        _config.setName(_name);
                        UserService.instance.getOtt(context, _email);
                      }
                    : null,
                fontSize: 18,
              ),
            ),
            Expanded(child: Container()),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Theme.of(context).cardColor,
                      builder: (BuildContext context) {
                        return PricingWidget();
                      });
                },
                child: Container(
                  padding: EdgeInsets.all(32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "pricing",
                      ),
                      Icon(Icons.arrow_drop_up),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PricingWidget extends StatelessWidget {
  const PricingWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BillingPlans>(
      future: BillingService.instance.getBillingPlans(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return _buildPlans(context, snapshot.data);
        } else if (snapshot.hasError) {
          return Text("Oops, something went wrong.");
        }
        return loadWidget;
      },
    );
  }

  Container _buildPlans(BuildContext context, BillingPlans plans) {
    final planWidgets = List<BillingPlanWidget>();
    for (final plan in plans.plans) {
      planWidgets.add(BillingPlanWidget(plan));
    }
    final freePlan = plans.freePlan;
    return Container(
      height: 280,
      color: Theme.of(context).cardColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text(
            "pricing",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: planWidgets,
          ),
          Text("there is also a free trial of " +
              convertBytesToReadableFormat(freePlan.storage) +
              " for " +
              freePlan.duration.toString() +
              " " +
              freePlan.period),
          GestureDetector(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white38,
                ),
                Padding(padding: EdgeInsets.all(1)),
                Text(
                  "close",
                  style: TextStyle(
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }
}

class BillingPlanWidget extends StatelessWidget {
  final BillingPlan plan;

  const BillingPlanWidget(
    this.plan, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: Colors.grey[850],
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 20, 12, 20),
          child: Column(
            children: [
              Text(
                convertBytesToGBs(plan.storage, precision: 0).toString() +
                    " GB",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(4),
              ),
              Text(
                plan.price + " / " + plan.period,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
