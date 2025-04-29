import "dart:convert";
import "dart:typed_data";

import 'package:ente_auth/core/configuration.dart';
import "package:ente_auth/l10n/l10n.dart";
import "package:ente_auth/theme/ente_theme.dart";
import 'package:ente_auth/ui/common/dynamic_fab.dart';
import "package:ente_auth/utils/dialog_util.dart";
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:flutter/material.dart';
import "package:logging/logging.dart";

typedef OnPasswordVerifiedFn = Future<void> Function(Uint8List bytes);

class RequestPasswordVerificationPage extends StatefulWidget {
  final OnPasswordVerifiedFn onPasswordVerified;
  final Function? onPasswordError;

  const RequestPasswordVerificationPage({
    super.key,
    required this.onPasswordVerified,
    this.onPasswordError,
  });

  @override
  State<RequestPasswordVerificationPage> createState() =>
      _RequestPasswordVerificationPageState();
}

class _RequestPasswordVerificationPageState
    extends State<RequestPasswordVerificationPage> {
  final _logger = Logger((_RequestPasswordVerificationPageState).toString());
  final _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  String? email;
  bool _passwordInFocus = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    email = Configuration.instance.getEmail();
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
        buttonText: context.l10n.verifyPassword,
        onPressedFunction: () async {
          FocusScope.of(context).unfocus();
          final dialog = createProgressDialog(context, context.l10n.pleaseWait);
          await dialog.show();
          try {
            final attributes = Configuration.instance.getKeyAttributes()!;
            final Uint8List keyEncryptionKey = await CryptoUtil.deriveKey(
              utf8.encode(_passwordController.text),
              CryptoUtil.base642bin(attributes.kekSalt),
              attributes.memLimit,
              attributes.opsLimit,
            );
            CryptoUtil.decryptSync(
              CryptoUtil.base642bin(attributes.encryptedKey),
              keyEncryptionKey,
              CryptoUtil.base642bin(attributes.keyDecryptionNonce),
            );
            await dialog.show();
            // pop
            await widget.onPasswordVerified(keyEncryptionKey);
            await dialog.hide();
            Navigator.of(context).pop(true);
          } catch (e, s) {
            _logger.severe("Error while verifying password", e, s);
            await dialog.hide();
            if (widget.onPasswordError != null) {
              widget.onPasswordError!();
            } else {
              // ignore: unawaited_futures
              showErrorDialog(
                context,
                context.l10n.incorrectPasswordTitle,
                context.l10n.pleaseTryAgain,
              );
            }
          }
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
          child: AutofillGroup(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                  child: Text(
                    context.l10n.enterPassword,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 30,
                    left: 22,
                    right: 20,
                  ),
                  child: Text(
                    email ?? '',
                    style: getEnteTextTheme(context).smallMuted,
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
                      hintText: context.l10n.enterYourPasswordHint,
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
