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
import "package:photos/service_locator.dart";
import "package:photos/services/account/user_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import 'package:photos/ui/account/recovery_page.dart';
import 'package:photos/ui/common/dynamic_fab.dart';
import 'package:photos/ui/components/buttons/button_widget.dart'
    show ButtonAction;
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/components/text_input_widget_v2.dart";
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
  String? email;
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
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    FloatingActionButtonLocation? fabLocation() {
      if (isKeypadOpen) {
        return null;
      } else {
        return FloatingActionButtonLocation.centerFloat;
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      backgroundColor: colorScheme.backgroundColour,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.backgroundColour,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colorScheme.content,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          AppLocalizations.of(context).enterPassword,
          style: textTheme.largeBold,
        ),
        centerTitle: true,
      ),
      body: _getBody(colorScheme, textTheme),
      floatingActionButton: DynamicFAB(
        key: const ValueKey("verifyPasswordButton"),
        isKeypadOpen: isKeypadOpen,
        isFormValid: _passwordController.text.isNotEmpty,
        buttonText: AppLocalizations.of(context).logInLabel,
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
    await flagService.tryRefreshFlags();
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

  Widget _getBody(EnteColorScheme colorScheme, EnteTextTheme textTheme) {
    return SafeArea(
      child: AutofillGroup(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
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
              TextInputWidgetV2(
                key: const ValueKey("passwordInputField"),
                label: AppLocalizations.of(context).password,
                isRequired: true,
                hintText: AppLocalizations.of(context).enterYourPassword,
                textEditingController: _passwordController,
                isPasswordInput: true,
                autoCorrect: false,
                onChange: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ButtonWidgetV2(
                    buttonType: ButtonTypeV2.link,
                    labelText: AppLocalizations.of(context).changeEmail,
                    buttonSize: ButtonSizeV2.small,
                    onTap: () async {
                      final dialog = createProgressDialog(
                        context,
                        AppLocalizations.of(context).pleaseWait,
                      );
                      await dialog.show();
                      await Configuration.instance.logout();
                      await dialog.hide();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                  ButtonWidgetV2(
                    buttonType: ButtonTypeV2.link,
                    labelText: AppLocalizations.of(context).forgotPassword,
                    buttonSize: ButtonSizeV2.small,
                    onTap: () async {
                      // ignore: unawaited_futures
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) {
                            return const RecoveryPage();
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
