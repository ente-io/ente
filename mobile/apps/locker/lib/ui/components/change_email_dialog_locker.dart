import 'dart:async';

import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_utils/email_util.dart';
import 'package:flutter/material.dart';
import "package:locker/ui/components/gradient_button.dart";

class ChangeEmailDialogLocker extends StatefulWidget {
  const ChangeEmailDialogLocker({super.key});

  @override
  State<ChangeEmailDialogLocker> createState() =>
      _ChangeEmailDialogLockerState();
}

class _ChangeEmailDialogLockerState extends State<ChangeEmailDialogLocker> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Validation states
  String _email = '';
  String _password = '';

  bool get _isFormValid =>
      _email.isNotEmpty && isValidEmail(_email) && _password.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      setState(() {
        _email = _emailController.text.trim();
      });
    });
    _passwordController.addListener(() {
      setState(() {
        _password = _passwordController.text;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Dialog(
      backgroundColor: colorScheme.backgroundElevated2,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change Email',
                  style: textTheme.h3Bold,
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.fillFaint,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: colorScheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: _email.isNotEmpty && isValidEmail(_email)
                    ? colorScheme.primary500.withValues(alpha: 0.05)
                    : colorScheme.fillFaint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _email.isNotEmpty && isValidEmail(_email)
                      ? colorScheme.primary500.withValues(alpha: 0.3)
                      : colorScheme.strokeFaint,
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your new email address',
                  hintStyle: textTheme.body.copyWith(
                    color: colorScheme.textMuted,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: InputBorder.none,
                ),
                style: textTheme.body.copyWith(
                  color: colorScheme.textBase,
                ),
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofocus: true,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: _password.isNotEmpty
                    ? colorScheme.primary500.withValues(alpha: 0.05)
                    : colorScheme.fillFaint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _password.isNotEmpty
                      ? colorScheme.primary500.withValues(alpha: 0.3)
                      : colorScheme.strokeFaint,
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your current password',
                  hintStyle: textTheme.body.copyWith(
                    color: colorScheme.textMuted,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: InputBorder.none,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: colorScheme.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                style: textTheme.body.copyWith(
                  color: colorScheme.textBase,
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSubmit(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _isFormValid
                  ? GradientButton(
                      onTap: _handleSubmit,
                      text: 'Apply changes',
                    )
                  : Container(
                      height: 56, // Match GradientButton height
                      decoration: BoxDecoration(
                        color: colorScheme.fillMuted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Apply changes',
                        style: textTheme.bodyBold.copyWith(
                          color: colorScheme.textFaint,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (!_isFormValid) return;

    try {
      await UserService.instance.sendOtt(
        context,
        _email,
        isChangeEmail: true,
      );
    } catch (e) {
      if (mounted) {
        unawaited(
          showErrorDialog(
            context,
            'Error',
            'Failed to send verification email. Please try again.',
          ),
        );
      }
    }
  }
}

Future<void> showChangeEmailDialogLocker(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const ChangeEmailDialogLocker();
    },
  );
}
