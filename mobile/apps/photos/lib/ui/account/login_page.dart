import 'dart:async';

import 'package:email_validator/email_validator.dart';
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/core/errors.dart";
import "package:photos/gateways/users/models/srp.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/account/login_pwd_verification_page.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/components/models/text_input_type_v2.dart";
import "package:photos/ui/components/text_input_widget_v2.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  bool _emailIsValid = false;
  bool _showValidationMessage = false;
  String? _email;
  Timer? _validationTimer;
  final _config = Configuration.instance;
  final Logger _logger = Logger('_LoginPageState');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if ((_config.getEmail() ?? '').isNotEmpty) {
      _updateEmail(_config.getEmail()!);
    } else if (kDebugMode) {
      _updateEmail(const String.fromEnvironment("email"));
    }
  }

  void _updateEmail(String value) {
    if (value.isEmpty) return;
    _email = value.trim();
    _emailController.text = _email!;
    _emailIsValid = EmailValidator.validate(_email!);
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          AppLocalizations.of(context).logInLabel,
          style: textTheme.largeBold,
        ),
        centerTitle: true,
      ),
      body: _getBody(colorScheme, textTheme),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ButtonWidgetV2(
          key: const ValueKey("logInButton"),
          buttonType: ButtonTypeV2.primary,
          labelText: AppLocalizations.of(context).continueLabel,
          isDisabled: !_emailIsValid,
          onTap: _emailIsValid ? _onLoginPressed : null,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _getBody(EnteColorScheme colorScheme, EnteTextTheme textTheme) {
    return AutofillGroup(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            TextInputWidgetV2(
              key: const ValueKey("emailInputField"),
              label: AppLocalizations.of(context).email,
              hintText: AppLocalizations.of(context).enterYourEmailAddress,
              textEditingController: _emailController,
              keyboardType: TextInputType.emailAddress,
              autoCorrect: false,
              autoFocus: true,
              isRequired: true,
              onChange: _onEmailChanged,
              message: _showValidationMessage
                  ? (_emailIsValid
                      ? AppLocalizations.of(context).validEmailAddress
                      : AppLocalizations.of(context).invalidEmailAddress)
                  : null,
              messageType: _showValidationMessage
                  ? (_emailIsValid
                      ? TextInputMessageType.success
                      : TextInputMessageType.alert)
                  : TextInputMessageType.guide,
            ),
          ],
        ),
      ),
    );
  }

  void _onEmailChanged(String value) {
    _validationTimer?.cancel();

    final trimmed = value.trim();
    final isValid = EmailValidator.validate(trimmed);

    setState(() {
      _email = trimmed;
      _emailIsValid = isValid;
      _showValidationMessage = false;
    });

    if (trimmed.isNotEmpty) {
      _validationTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showValidationMessage = true;
          });
        }
      });
    }
  }

  Future<void> _onLoginPressed() async {
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
  }
}
