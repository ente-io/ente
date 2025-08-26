import 'dart:async';
import "dart:typed_data";

import "package:ente_crypto/ente_crypto.dart";
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/account/recovery_page.dart';
import 'package:photos/ui/common/dynamic_fab.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/tabs/home_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';

class PasswordReentryPage extends StatefulWidget {
  const PasswordReentryPage({super.key});

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
    email = Configuration.instance.getEmail();
    _volatilePassword = Configuration.instance.getVolatilePassword();
    if (_volatilePassword != null) {
      _passwordController.text = _volatilePassword!;
      Future.delayed(
        Duration.zero,
        () => verifyPassword(_volatilePassword!),
      );
    }
    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordInFocus = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
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
        buttonText: AppLocalizations.of(context).verifyPassword,
        onPressedFunction: () async {
          FocusScope.of(context).unfocus();
          await verifyPassword(_passwordController.text);
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Future<void> verifyPassword(String password) async {
    FocusScope.of(context).unfocus();
    final dialog =
        createProgressDialog(context, AppLocalizations.of(context).pleaseWait);
    await dialog.show();
    try {
      final kek = await Configuration.instance.decryptSecretsAndGetKeyEncKey(
        password,
        Configuration.instance.getKeyAttributes()!,
      );
      _registerSRPForExistingUsers(kek).ignore();
    } on KeyDerivationError catch (e, s) {
      _logger.severe("Password verification failed", e, s);
      await dialog.hide();
      final dialogChoice = await showChoiceDialog(
        context,
        title: AppLocalizations.of(context).recreatePasswordTitle,
        body: AppLocalizations.of(context).recreatePasswordBody,
        firstButtonLabel: AppLocalizations.of(context).useRecoveryKey,
      );
      if (dialogChoice!.action == ButtonAction.first) {
        // ignore: unawaited_futures
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const RecoveryPage();
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
        title: AppLocalizations.of(context).incorrectPasswordTitle,
        body: AppLocalizations.of(context).pleaseTryAgain,
        firstButtonLabel: AppLocalizations.of(context).contactSupport,
        secondButtonLabel: AppLocalizations.of(context).ok,
      );
      if (dialogChoice!.action == ButtonAction.first) {
        await sendLogs(
          context,
          AppLocalizations.of(context).contactSupport,
          "support@ente.io",
          postShare: () {},
        );
      }
      return;
    }
    await dialog.hide();
    Configuration.instance.resetVolatilePassword();
    Bus.instance.fire(SubscriptionPurchasedEvent());
    unawaited(
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return const HomeWidget();
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
                    AppLocalizations.of(context).welcomeBack,
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
                      hintText: AppLocalizations.of(context).enterYourPassword,
                      filled: true,
                      fillColor: getEnteColorScheme(context).fillFaint,
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Divider(
                    thickness: 1,
                    color: getEnteColorScheme(context).strokeFaint,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) {
                                return const RecoveryPage();
                              },
                            ),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context).forgotPassword,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final dialog = createProgressDialog(
                            context,
                            AppLocalizations.of(context).pleaseWait,
                          );
                          await dialog.show();
                          await Configuration.instance.logout();
                          await dialog.hide();
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: Text(
                          AppLocalizations.of(context).changeEmail,
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
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
