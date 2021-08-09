import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/recovery_page.dart';
import 'package:photos/utils/dialog_util.dart';

class PasswordReentryPage extends StatefulWidget {
  PasswordReentryPage({Key key}) : super(key: key);

  @override
  _PasswordReentryPageState createState() => _PasswordReentryPageState();
}

class _PasswordReentryPageState extends State<PasswordReentryPage> {
  final _passwordController = TextEditingController();
  FocusNode _passwordFocusNode = FocusNode();
  bool _passwordInFocus = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordInFocus = _passwordFocusNode.hasFocus;
      });
    });
  }

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
              suffixIcon: _passwordInFocus
                  ? IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    )
                  : null,
            ),
            style: TextStyle(
              fontSize: 14,
            ),
            controller: _passwordController,
            autofocus: false,
            autocorrect: false,
            obscureText: !_passwordVisible,
            keyboardType: TextInputType.visiblePassword,
            focusNode: _passwordFocusNode,
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
            "log in",
            fontSize: 18,
            onPressed: _passwordController.text.isNotEmpty
                ? () async {
                    final dialog =
                        createProgressDialog(context, "please wait...");
                    await dialog.show();
                    try {
                      await Configuration.instance.decryptAndSaveSecrets(
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
                    Bus.instance.fire(SubscriptionPurchasedEvent());
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                : null,
          ),
        ),
        Padding(padding: EdgeInsets.all(30)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
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
            padding: EdgeInsets.all(10),
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
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final dialog = createProgressDialog(context, "please wait...");
            await dialog.show();
            await Configuration.instance.logout();
            await dialog.hide();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Container(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                "change email?",
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
