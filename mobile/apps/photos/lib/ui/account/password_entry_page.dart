import "dart:async";

import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:password_strength/password_strength.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/account_configured_event.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import "package:photos/gateways/users/models/key_gen_result.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import 'package:photos/ui/account/recovery_key_page.dart';
import 'package:photos/ui/common/dynamic_fab.dart';
import 'package:photos/ui/common/web_page.dart';
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/models/text_input_type_v2.dart";
import "package:photos/ui/components/text_input_widget_v2.dart";
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/utils/dialog_util.dart';
import "package:styled_text/styled_text.dart";

enum PasswordEntryMode {
  set,
  update,
  reset,
}

class PasswordEntryPage extends StatefulWidget {
  final PasswordEntryMode mode;

  const PasswordEntryPage({
    required this.mode,
    super.key,
  });

  @override
  State<PasswordEntryPage> createState() => _PasswordEntryPageState();
}

class _PasswordEntryPageState extends State<PasswordEntryPage> {
  static const kMildPasswordStrengthThreshold = 0.4;
  static const kStrongPasswordStrengthThreshold = 0.7;

  final _logger = Logger((_PasswordEntryPageState).toString());
  final _passwordController1 = TextEditingController();
  final _passwordController2 = TextEditingController();
  String? _volatilePassword;
  String _passwordInInputBox = '';
  String _passwordInInputConfirmationBox = '';
  double _passwordStrength = 0.0;

  bool _passwordsMatch = false;
  bool _isPasswordValid = false;
  bool _showPasswordStrength = false;
  bool _showConfirmPasswordValidation = false;
  Timer? _passwordStrengthTimer;
  Timer? _confirmPasswordTimer;

  @override
  void initState() {
    super.initState();
    _volatilePassword = Configuration.instance.getVolatilePassword();
    if (_volatilePassword != null) {
      Future.delayed(
        Duration.zero,
        () => _showRecoveryCodeDialog(_volatilePassword!),
      );
    }
  }

  @override
  void dispose() {
    _passwordStrengthTimer?.cancel();
    _confirmPasswordTimer?.cancel();
    _passwordController1.dispose();
    _passwordController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    String title = AppLocalizations.of(context).setPasswordTitle;
    if (widget.mode == PasswordEntryMode.update) {
      title = AppLocalizations.of(context).changePasswordTitle;
    } else if (widget.mode == PasswordEntryMode.reset) {
      title = AppLocalizations.of(context).resetPasswordTitle;
    } else if (_volatilePassword != null) {
      title = AppLocalizations.of(context).encryptionKeys;
    }

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
        leading: widget.mode == PasswordEntryMode.reset
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                color: colorScheme.content,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
        title: Text(
          title,
          style: textTheme.largeBold,
        ),
        centerTitle: true,
      ),
      body: _volatilePassword != null
          ? const SizedBox.shrink()
          : _getBody(colorScheme, textTheme),
      floatingActionButton: _volatilePassword != null
          ? null
          : DynamicFAB(
              isKeypadOpen: isKeypadOpen,
              isFormValid: _passwordsMatch && _isPasswordValid,
              buttonText: title,
              onPressedFunction: () async {
                if (widget.mode == PasswordEntryMode.set) {
                  await _showRecoveryCodeDialog(_passwordController1.text);
                } else {
                  _updatePassword();
                }
                FocusScope.of(context).unfocus();
              },
            ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Widget _getBody(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final email = Configuration.instance.getEmail();

    String? passwordMessage;
    TextInputMessageType passwordMessageType = TextInputMessageType.guide;

    if (_passwordInInputBox.isNotEmpty && _showPasswordStrength) {
      if (_passwordStrength > kStrongPasswordStrengthThreshold) {
        passwordMessage = AppLocalizations.of(context).strongPassword;
        passwordMessageType = TextInputMessageType.success;
      } else if (_passwordStrength > kMildPasswordStrengthThreshold) {
        passwordMessage = AppLocalizations.of(context).moderateStrength;
        passwordMessageType = TextInputMessageType.alert;
      } else {
        passwordMessage = AppLocalizations.of(context).weakStrength;
        passwordMessageType = TextInputMessageType.alert;
      }
    }

    String? confirmPasswordMessage;
    TextInputMessageType confirmPasswordMessageType =
        TextInputMessageType.guide;

    if (_passwordInInputConfirmationBox.isNotEmpty &&
        _passwordInInputBox.isNotEmpty &&
        _showConfirmPasswordValidation) {
      if (_passwordsMatch) {
        confirmPasswordMessage = AppLocalizations.of(context).passwordsMatch;
        confirmPasswordMessageType = TextInputMessageType.success;
      } else {
        confirmPasswordMessage =
            AppLocalizations.of(context).passwordsDontMatch;
        confirmPasswordMessageType = TextInputMessageType.error;
      }
    }

    return SafeArea(
      child: AutofillGroup(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                widget.mode == PasswordEntryMode.set
                    ? AppLocalizations.of(context).enterPasswordToEncrypt
                    : AppLocalizations.of(context).enterNewPasswordToEncrypt,
                style: textTheme.body.copyWith(color: colorScheme.textMuted),
              ),
              const SizedBox(height: 8),
              StyledText(
                text: AppLocalizations.of(context).passwordWarning,
                style: textTheme.body.copyWith(color: colorScheme.textMuted),
                tags: {
                  'underline': StyledTextTag(
                    style: textTheme.body.copyWith(
                      color: colorScheme.textMuted,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                },
              ),
              const SizedBox(height: 24),
              Visibility(
                visible: false,
                child: TextFormField(
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  initialValue: email,
                  textInputAction: TextInputAction.next,
                ),
              ),
              TextInputWidgetV2(
                label: AppLocalizations.of(context).password,
                hintText: AppLocalizations.of(context).password,
                textEditingController: _passwordController1,
                isPasswordInput: true,
                isRequired: true,
                autoCorrect: false,
                autofillHints: const [AutofillHints.newPassword],
                message: passwordMessage,
                messageType: passwordMessageType,
                onChange: (password) {
                  _passwordStrengthTimer?.cancel();
                  setState(() {
                    _passwordInInputBox = password;
                    _passwordStrength = estimatePasswordStrength(password);
                    _isPasswordValid =
                        _passwordStrength >= kMildPasswordStrengthThreshold;
                    _passwordsMatch =
                        _passwordInInputBox == _passwordInInputConfirmationBox;
                    _showPasswordStrength = false;
                  });
                  _passwordStrengthTimer = Timer(
                    const Duration(seconds: 1),
                    () {
                      if (mounted) {
                        setState(() {
                          _showPasswordStrength = true;
                        });
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextInputWidgetV2(
                label: AppLocalizations.of(context).confirmPassword,
                hintText: AppLocalizations.of(context).confirmPassword,
                textEditingController: _passwordController2,
                isPasswordInput: true,
                isRequired: true,
                autoCorrect: false,
                autofillHints: const [],
                finishAutofillContextOnEditingComplete: true,
                message: confirmPasswordMessage,
                messageType: confirmPasswordMessageType,
                onChange: (cnfPassword) {
                  _confirmPasswordTimer?.cancel();
                  setState(() {
                    _passwordInInputConfirmationBox = cnfPassword;
                    _showConfirmPasswordValidation = false;
                    if (_passwordInInputBox.isNotEmpty) {
                      _passwordsMatch = _passwordInInputBox ==
                          _passwordInInputConfirmationBox;
                    }
                  });
                  _confirmPasswordTimer = Timer(
                    const Duration(seconds: 1),
                    () {
                      if (mounted) {
                        setState(() {
                          _showConfirmPasswordValidation = true;
                        });
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ButtonWidgetV2(
                  buttonType: ButtonTypeV2.link,
                  labelText: AppLocalizations.of(context).howItWorks,
                  buttonSize: ButtonSizeV2.small,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) {
                          return WebPage(
                            AppLocalizations.of(context).howItWorks,
                            "https://ente.io/architecture",
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _updatePassword() async {
    final logOutFromOthers = await logOutFromOtherDevices(context);
    final dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).generatingEncryptionKeys,
    );
    await dialog.show();
    try {
      final result = await Configuration.instance
          .getAttributesForNewPassword(_passwordController1.text);
      await UserService.instance.updateKeyAttributes(
        result.item1,
        result.item2,
        logoutOtherDevices: logOutFromOthers,
      );
      await dialog.hide();
      showShortToast(
        context,
        AppLocalizations.of(context).passwordChangedSuccessfully,
      );
      Navigator.of(context).pop();
      if (widget.mode == PasswordEntryMode.reset) {
        Bus.instance.fire(SubscriptionPurchasedEvent());
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e, s) {
      _logger.severe(e, s);
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<bool> logOutFromOtherDevices(BuildContext context) async {
    bool logOutFromOther = true;
    await showChoiceDialog(
      context,
      title: context.l10n.signOutFromOtherDevices,
      body: context.l10n.signOutOtherBody,
      isDismissible: false,
      firstButtonLabel: context.l10n.signOutOtherDevices,
      firstButtonType: ButtonType.critical,
      firstButtonOnTap: () async {
        logOutFromOther = true;
      },
      secondButtonLabel: context.l10n.doNotSignOut,
      secondButtonOnTap: () async {
        logOutFromOther = false;
      },
    );
    return logOutFromOther;
  }

  Future<void> _showRecoveryCodeDialog(String password) async {
    final dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).generatingEncryptionKeys,
    );
    await dialog.show();
    try {
      final KeyGenResult result =
          await Configuration.instance.generateKey(password);
      Configuration.instance.resetVolatilePassword();
      await dialog.hide();
      onDone() async {
        final dialog = createProgressDialog(
          context,
          AppLocalizations.of(context).pleaseWait,
        );
        await dialog.show();
        try {
          await UserService.instance.setAttributes(result);
          await dialog.hide();
          Configuration.instance.resetVolatilePassword();
          Bus.instance.fire(AccountConfiguredEvent());
          // ignore: unawaited_futures
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return getSubscriptionPage(isOnBoarding: true);
              },
            ),
            (route) => route.isFirst,
          );
        } catch (e, s) {
          _logger.severe(e, s);
          await dialog.hide();
          await showGenericErrorDialog(context: context, error: e);
        }
      }

      // ignore: unawaited_futures
      routeToPage(
        context,
        RecoveryKeyPage(
          result.privateKeyAttributes.recoveryKey,
          AppLocalizations.of(context).continueLabel,
          onDone: onDone,
          isOnboarding: true,
        ),
      );
    } catch (e) {
      _logger.severe(e);
      await dialog.hide();
      if (e is UnsupportedError) {
        // ignore: unawaited_futures
        showErrorDialog(
          context,
          AppLocalizations.of(context).insecureDevice,
          AppLocalizations.of(context)
              .sorryWeCouldNotGenerateSecureKeysOnThisDevicennplease,
        );
      } else {
        await showGenericErrorDialog(context: context, error: e);
      }
    }
  }
}
