import 'package:email_validator/email_validator.dart';
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/core/errors.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/api/user/srp.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/account/login_pwd_verification_page.dart";
import 'package:photos/ui/common/dynamic_fab.dart';
import 'package:photos/ui/common/web_page.dart';
import "package:styled_text/styled_text.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _config = Configuration.instance;
  bool _emailIsValid = false;
  String? _email;
  Color? _emailInputFieldColor;
  final Logger _logger = Logger('_LoginPageState');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if ((_config.getEmail() ?? '').isNotEmpty) {
      updateEmail(_config.getEmail()!);
    } else if (kDebugMode) {
      updateEmail(const String.fromEnvironment("email"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeypadOpen = MediaQuery.viewInsetsOf(context).bottom > 100;

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
        key: const ValueKey("logInButton"),
        isKeypadOpen: isKeypadOpen,
        isFormValid: _emailIsValid,
        buttonText: AppLocalizations.of(context).logInLabel,
        onPressedFunction: () async {
          await UserService.instance.setEmail(_email!);
          Configuration.instance.resetVolatilePassword();
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
            // ignore: unawaited_futures
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return LoginPasswordVerificationPage(
                    srpAttributes: attr!,
                  );
                },
              ),
            );
          } else {
            await UserService.instance.sendOtt(
              context,
              _email!,
              isCreateAccountScreen: false,
              purpose: "login",
            );
          }
          FocusScope.of(context).unfocus();
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Widget _getBody() {
    final l10n = context.l10n;
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
                    l10n.accountWelcomeBack,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: TextFormField(
                    key: const ValueKey("emailInputField"),
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      fillColor: _emailInputFieldColor,
                      filled: true,
                      hintText: l10n.email,
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
                              color: Theme.of(context)
                                  .inputDecorationTheme
                                  .focusedBorder!
                                  .borderSide
                                  .color,
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        updateEmail(value);
                      });
                    },
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    initialValue: _email,
                    autofocus: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Divider(
                    thickness: 1,
                    color: getEnteColorScheme(context).strokeFaint,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: StyledText(
                          text: AppLocalizations.of(context).loginTerms,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontSize: 12),
                          tags: {
                            'u-terms': StyledTextActionTag(
                              (String? text, Map<String?, String?> attrs) =>
                                  Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return WebPage(
                                      AppLocalizations.of(context)
                                          .termsOfServicesTitle,
                                      "https://ente.io/terms",
                                    );
                                  },
                                ),
                              ),
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            'u-policy': StyledTextActionTag(
                              (String? text, Map<String?, String?> attrs) =>
                                  Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return WebPage(
                                      AppLocalizations.of(context)
                                          .privacyPolicyTitle,
                                      "https://ente.io/privacy",
                                    );
                                  },
                                ),
                              ),
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          },
                        ),
                      ),
                      const Expanded(
                        flex: 1,
                        child: SizedBox.shrink(),
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

  void updateEmail(String value) {
    _email = value.trim();
    _emailIsValid = EmailValidator.validate(_email!);
    if (_emailIsValid) {
      _emailInputFieldColor = const Color.fromRGBO(45, 194, 98, 0.2);
    } else {
      _emailInputFieldColor = getEnteColorScheme(context).fillFaint;
    }
  }
}
