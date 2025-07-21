import 'dart:async';
import 'dart:typed_data';

import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_accounts/models/errors.dart';
import 'package:ente_configuration/base_configuration.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/components/buttons/dynamic_fab.dart';
import 'package:ente_ui/pages/base_home_page.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_utils/email_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class PasswordReentryPage extends StatefulWidget {
  final BaseConfiguration config;
  final BaseHomePage homePage;

  const PasswordReentryPage(
    this.config,
    this.homePage, {
    super.key,
  });

  @override
  State<PasswordReentryPage> createState() => _PasswordReentryPageState();
}

class _PasswordReentryPageState extends State<PasswordReentryPage> {
  final _logger = Logger((_PasswordReentryPageState).toString());
  final _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  String? email;
  bool _passwordInFocus = false;
  bool _passwordVisible = false;
  String? _volatilePassword;

  @override
  void initState() {
    super.initState();
    email = widget.config.getEmail();
    _volatilePassword = widget.config.getVolatilePassword();
    if (_volatilePassword != null) {
      _passwordController.text = _volatilePassword!;
      Future.delayed(
        Duration.zero,
        () => verifyPassword(_volatilePassword!, usingVolatilePassword: true),
      );
    }
    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordInFocus = _passwordFocusNode.hasFocus;
      });
    });
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
        key: const ValueKey("verifyPasswordButton"),
        isKeypadOpen: isKeypadOpen,
        isFormValid: _passwordController.text.isNotEmpty,
        buttonText: context.strings.verifyPassword,
        onPressedFunction: () async {
          FocusScope.of(context).unfocus();
          await verifyPassword(_passwordController.text);
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Future<void> verifyPassword(
    String password, {
    bool usingVolatilePassword = false,
  }) async {
    FocusScope.of(context).unfocus();
    final dialog = createProgressDialog(context, context.strings.pleaseWait);
    await dialog.show();
    if (usingVolatilePassword) {
      _logger.info("Using volatile password");
    }
    try {
      final kek = await widget.config.decryptSecretsAndGetKeyEncKey(
        password,
        widget.config.getKeyAttributes()!,
      );
      _registerSRPForExistingUsers(kek).ignore();
    } on KeyDerivationError catch (e, s) {
      _logger.severe("Password verification failed", e, s);
      await dialog.hide();
      final dialogChoice = await showChoiceDialog(
        context,
        title: context.strings.recreatePasswordTitle,
        body: context.strings.recreatePasswordBody,
        firstButtonLabel: context.strings.useRecoveryKey,
      );
      if (dialogChoice!.action == ButtonAction.first) {
        // ignore: unawaited_futures
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return RecoveryPage(
                widget.config,
                widget.homePage,
              );
            },
          ),
        );
      }
      return;
    } catch (e, s) {
      _logger.severe("Password verification failed", e, s);
      await dialog.hide();
      final dialogChoice = await showChoiceDialog(
        context,
        title: context.strings.incorrectPasswordTitle,
        body: context.strings.pleaseTryAgain,
        firstButtonLabel: context.strings.contactSupport,
        secondButtonLabel: context.strings.ok,
      );
      if (dialogChoice!.action == ButtonAction.first) {
        await sendLogs(
          context,
          context.strings.contactSupport,
          postShare: () {},
        );
      }
      return;
    }
    widget.config.resetVolatilePassword();
    await dialog.hide();
    unawaited(
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return widget.homePage;
          },
        ),
        (route) => false,
      ),
    );
  }

  Future<void> _registerSRPForExistingUsers(Uint8List key) async {
    bool shouldSetupSRP = false;
    try {
      // ignore: unused_local_variable
      final attr = await UserService.instance.getSrpAttributes(email!);
    } on SrpSetupNotCompleteError {
      shouldSetupSRP = true;
    } catch (e, s) {
      _logger.severe("error while fetching attr", e, s);
    }
    if (shouldSetupSRP) {
      try {
        final Uint8List loginKey = await CryptoUtil.deriveLoginKey(key);
        await UserService.instance.registerOrUpdateSrp(loginKey);
      } catch (e, s) {
        _logger.severe("error while setting up srp for existing users", e, s);
      }
    }
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
                Visibility(
                  // hidden textForm for suggesting auto-fill service for saving
                  // password
                  visible: false,
                  child: TextFormField(
                    autofillHints: const [
                      AutofillHints.email,
                    ],
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    initialValue: email,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: TextFormField(
                    key: const ValueKey("passwordInputField"),
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      hintText: context.strings.enterYourPasswordHint,
                      filled: true,
                      contentPadding: const EdgeInsets.all(20),
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
                    style: const TextStyle(
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
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
                                return RecoveryPage(
                                  widget.config,
                                  widget.homePage,
                                );
                              },
                            ),
                          );
                        },
                        child: Center(
                          child: Text(
                            context.strings.forgotPassword,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final dialog = createProgressDialog(
                            context,
                            context.strings.pleaseWait,
                          );
                          await dialog.show();
                          await widget.config.logout();
                          await dialog.hide();
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: Center(
                          child: Text(
                            context.strings.changeEmail,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
