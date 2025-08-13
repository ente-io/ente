import "package:email_validator/email_validator.dart";
import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_accounts/models/errors.dart';
import 'package:ente_configuration/base_configuration.dart';
import "package:ente_strings/ente_strings.dart";
import 'package:ente_ui/components/buttons/dynamic_fab.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_utils/platform_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import "package:styled_text/tags/styled_text_tag_action.dart";
import "package:styled_text/widgets/styled_text.dart";

class LoginPage extends StatefulWidget {
  final BaseConfiguration config;

  const LoginPage(this.config, {super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _emailIsValid = false;
  String? _email;
  Color? _emailInputFieldColor;
  final Logger _logger = Logger('_LoginPageState');

  Future<void> onPressed() async {
    await UserService.instance.setEmail(_email!);
    widget.config.resetVolatilePassword();
    SrpAttributes? attr;
    bool isEmailVerificationEnabled = true;
    try {
      attr = await UserService.instance.getSrpAttributes(_email!);
      isEmailVerificationEnabled = attr.isEmailMFAEnabled;
    } catch (e) {
      if (e is! SrpSetupNotCompleteError) {
        _logger.severe('Error getting SRP attributes', e);
      }
    }
    if (attr != null && !isEmailVerificationEnabled) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return LoginPasswordVerificationPage(
              widget.config,
              attr!,
            );
          },
        ),
      );
    } else {
      await UserService.instance.sendOtt(
        context,
        _email!,
        isCreateAccountScreen: false,
        purpose: 'login',
      );
    }
    FocusScope.of(context).unfocus();
  }

  @override
  void initState() {
    _email = widget.config.getEmail();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;

    FloatingActionButtonLocation? fabLocation() {
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
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _getBody(),
      floatingActionButton: DynamicFAB(
        isKeypadOpen: isKeypadOpen,
        isFormValid: _emailIsValid,
        buttonText: context.strings.logInLabel,
        onPressedFunction: onPressed,
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Widget _getBody() {
    return Column(
      children: [
        Expanded(
          child: AutofillGroup(
            child: ListView(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  child: Text(
                    context.strings.welcomeBack,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: TextFormField(
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted:
                        _emailIsValid ? (value) => onPressed() : null,
                    decoration: InputDecoration(
                      fillColor: _emailInputFieldColor,
                      filled: true,
                      hintText: context.strings.email,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      suffixIcon: _emailIsValid
                          ? Icon(
                              Icons.check,
                              size: 20,
                              color: getEnteColorScheme(context).primary300,
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _email = value.trim();
                        _emailIsValid = EmailValidator.validate(_email!);
                        if (_emailIsValid) {
                          _emailInputFieldColor = getEnteColorScheme(context)
                              .primary300
                              .withOpacity(0.2);
                        } else {
                          _emailInputFieldColor = null;
                        }
                      });
                    },
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    //initialValue: _email,
                    autofocus: true,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: StyledText(
                          text: context.strings.loginTerms,
                          style: getEnteTextTheme(context).small,
                          tags: {
                            'u-terms': StyledTextActionTag(
                              (String? text, Map<String?, String?> attrs) =>
                                  PlatformUtil.openWebView(
                                context,
                                context.strings.termsOfServicesTitle,
                                "https://ente.io/terms",
                              ),
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            'u-policy': StyledTextActionTag(
                              (String? text, Map<String?, String?> attrs) =>
                                  PlatformUtil.openWebView(
                                context,
                                context.strings.privacyPolicyTitle,
                                "https://ente.io/privacy",
                              ),
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          },
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.all(8)),
      ],
    );
  }
}
