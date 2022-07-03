import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/ui/account/recovery_page.dart';
import 'package:photos/ui/common/dynamicFAB.dart';
import 'package:photos/ui/home_widget.dart';
import 'package:photos/utils/dialog_util.dart';

class PasswordReentryPage extends StatefulWidget {
  PasswordReentryPage({Key key}) : super(key: key);

  @override
  State<PasswordReentryPage> createState() => _PasswordReentryPageState();
}

class _PasswordReentryPageState extends State<PasswordReentryPage> {
  final _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
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
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;

    FloatingActionButtonLocation fabLocation() {
      if (isKeypadOpen) {
        return null;
      } else {
        return FloatingActionButtonLocation.centerFloat;
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _getBody(),
      floatingActionButton: DynamicFAB(
        isKeypadOpen: isKeypadOpen,
        isFormValid: _passwordController.text.isNotEmpty,
        buttonText: 'Log in',
        onPressedFunction: () async {
          FocusScope.of(context).unfocus();
          final dialog = createProgressDialog(context, "Please wait...");
          await dialog.show();
          try {
            await Configuration.instance.decryptAndSaveSecrets(
              _passwordController.text,
              Configuration.instance.getKeyAttributes(),
            );
          } catch (e) {
            Logger("PRP").warning(e);
            await dialog.hide();
            showErrorDialog(context, "Incorrect password", "Please try again");
            return;
          }
          await dialog.hide();
          Bus.instance.fire(SubscriptionPurchasedEvent());
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return HomeWidget();
              },
            ),
            (route) => false,
          );
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Widget _getBody() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: TextFormField(
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    hintText: "Enter your password",
                    filled: true,
                    contentPadding: EdgeInsets.all(20),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    suffixIcon: _passwordInFocus
                        ? IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).iconTheme.color,
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
                  autofocus: true,
                  autocorrect: false,
                  obscureText: !_passwordVisible,
                  keyboardType: TextInputType.visiblePassword,
                  focusNode: _passwordFocusNode,
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Divider(
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                      child: Center(
                        child: Text(
                          "Forgot password",
                          style: Theme.of(context).textTheme.subtitle1.copyWith(
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final dialog =
                            createProgressDialog(context, "Please wait...");
                        await dialog.show();
                        await Configuration.instance.logout();
                        await dialog.hide();
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      child: Center(
                        child: Text(
                          "Change email",
                          style: Theme.of(context).textTheme.subtitle1.copyWith(
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
