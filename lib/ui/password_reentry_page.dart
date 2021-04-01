import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/recovery_page.dart';
import 'package:photos/ui/subscription_page.dart';
import 'package:photos/utils/dialog_util.dart';

class PasswordReentryPage extends StatefulWidget {
  PasswordReentryPage({Key key}) : super(key: key);

  @override
  _PasswordReentryPageState createState() => _PasswordReentryPageState();
}

class _PasswordReentryPageState extends State<PasswordReentryPage> {
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "password",
        ),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
          child: TextFormField(
            decoration: InputDecoration(
              hintText: "enter your password",
              contentPadding: EdgeInsets.all(20),
            ),
            style: TextStyle(
              fontSize: 14,
            ),
            controller: _passwordController,
            autofocus: false,
            autocorrect: false,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            onChanged: (_) {
              setState(() {});
            },
          ),
        ),
        Padding(padding: EdgeInsets.all(12)),
        Container(
          padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
          width: double.infinity,
          height: 64,
          child: button(
            "sign in",
            fontSize: 18,
            onPressed: _passwordController.text.isNotEmpty
                ? () async {
                    final dialog =
                        createProgressDialog(context, "please wait...");
                    await dialog.show();
                    try {
                      await Configuration.instance.decryptAndSaveKey(
                          _passwordController.text,
                          Configuration.instance.getKeyAttributes());
                    } catch (e) {
                      Logger("PRP").warning(e);
                      await dialog.hide();
                      showErrorDialog(
                          context, "incorrect password", "please try again");
                      return;
                    }
                    await dialog.hide();
                    if (!BillingService.instance.hasActiveSubscription()) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (BuildContext context) {
                            return SubscriptionPage(isOnboarding: true);
                          },
                        ),
                      );
                    } else {
                      Bus.instance.fire(SubscriptionPurchasedEvent());
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  }
                : null,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return RecoveryPage();
                },
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text(
                "forgot password?",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
