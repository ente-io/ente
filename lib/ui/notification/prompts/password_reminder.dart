import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:pedantic/pedantic.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/local_authentication_service.dart';
import 'package:photos/services/user_remote_flag_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/account/password_entry_page.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/home_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';

class PasswordReminder extends StatefulWidget {
  const PasswordReminder({Key? key}) : super(key: key);

  @override
  State<PasswordReminder> createState() => _PasswordReminderState();
}

class _PasswordReminderState extends State<PasswordReminder> {
  final _passwordController = TextEditingController();
  final Logger _logger = Logger((_PasswordReminderState).toString());
  bool _password2Visible = false;
  bool _incorrectPassword = false;

  Future<void> _verifyRecoveryKey() async {
    final dialog = createProgressDialog(context, "Verifying password...");
    await dialog.show();
    try {
      final String inputKey = _passwordController.text;
      await Configuration.instance.verifyPassword(inputKey);
      await dialog.hide();
      UserRemoteFlagService.instance.stopPasswordReminder().ignore();
      // todo: change this as per figma once the component is ready
      await showErrorDialog(
        context,
        "Password verified",
        "Great! Thank you for verifying.\n"
            "\nPlease"
            " remember to keep your recovery key safely backed up.",
      );

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
    } catch (e, s) {
      _logger.severe("failed to verify password", e, s);
      await dialog.hide();
      _incorrectPassword = true;
      if (mounted) {
        setState(() => {});
      }
    }
  }

  Future<void> _onChangePasswordClick() async {
    try {
      final hasAuthenticated =
          await LocalAuthenticationService.instance.requestLocalAuthentication(
        context,
        "Please authenticate to change your password",
      );
      if (hasAuthenticated) {
        UserRemoteFlagService.instance.stopPasswordReminder().ignore();
        await routeToPage(
          context,
          const PasswordEntryPage(
            mode: PasswordEntryMode.update,
          ),
          forceCustomPageRoute: true,
        );
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
    } catch (e) {
      showGenericErrorDialog(context);
      return;
    }
  }

  Future<void> _onSkipClick() async {
    final enteTextTheme = getEnteTextTheme(context);
    final enteColor = getEnteColorScheme(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "You will not be able to access your photos if you forget "
          "your password.\n\nIf you do not remember your password, "
          "now is a good time to change it.",
          style: enteTextTheme.body.copyWith(
            color: enteColor.textMuted,
          ),
        ),
        const Padding(padding: EdgeInsets.all(8)),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: Theme.of(context).outlinedButtonTheme.style?.copyWith(
              textStyle: MaterialStateProperty.resolveWith<TextStyle>(
                (Set<MaterialState> states) {
                  return enteTextTheme.bodyBold;
                },
              ),
            ),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop('dialog');

              _onChangePasswordClick();
            },
            child: const Text(
              "Change password",
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.all(8)),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: Theme.of(context).outlinedButtonTheme.style?.copyWith(
              textStyle: MaterialStateProperty.resolveWith<TextStyle>(
                (Set<MaterialState> states) {
                  return enteTextTheme.bodyBold;
                },
              ),
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  return enteColor.fillFaint;
                },
              ),
              foregroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  return Theme.of(context).colorScheme.defaultTextColor;
                },
              ),
            ),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop('dialog');
            },
            child: Text(
              "Cancel",
              style: enteTextTheme.bodyBold,
            ),
          ),
        )
      ],
    );
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: enteColor.backgroundElevated,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.report_outlined,
                size: 36,
                color: getEnteColorScheme(context).strokeBase,
              ),
            ],
          ),
          content: content,
        );
      },
      barrierColor: enteColor.backdropBaseMute,
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enteTheme = Theme.of(context).colorScheme.enteTheme;
    final List<Widget> actions = <Widget>[];
    actions.add(
      PopupMenuButton(
        itemBuilder: (context) {
          return [
            PopupMenuItem(
              value: 1,
              child: SizedBox(
                width: 120,
                height: 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.report_outlined,
                      color: warning500,
                      size: 20,
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6)),
                    Text(
                      "Skip",
                      style: getEnteTextTheme(context)
                          .bodyBold
                          .copyWith(color: warning500),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        onSelected: (value) async {
          _onSkipClick();
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        actions: actions,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Password reminder',
                              style: enteTheme.textTheme.h3Bold,
                            ),
                            Text(
                              Configuration.instance.getEmail()!,
                              style: enteTheme.textTheme.small.copyWith(
                                color: enteTheme.colorScheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Enter your password to ensure you remember it."
                        "\n\nThe developer account we use to publish ente on App Store will change in the next version, so you will need to login again when the next version is released.",
                        style: enteTheme.textTheme.small
                            .copyWith(color: enteTheme.colorScheme.textMuted),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          filled: true,
                          hintText: "Password",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _password2Visible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context).iconTheme.color,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _password2Visible = !_password2Visible;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.all(20),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        controller: _passwordController,
                        autofocus: false,
                        autocorrect: false,
                        obscureText: !_password2Visible,
                        keyboardType: TextInputType.visiblePassword,
                        onChanged: (_) {
                          _incorrectPassword = false;
                          setState(() {});
                        },
                      ),
                      _incorrectPassword
                          ? const SizedBox(height: 2)
                          : const SizedBox.shrink(),
                      _incorrectPassword
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Incorrect password",
                                style: enteTheme.textTheme.small.copyWith(
                                  color: enteTheme.colorScheme.warning700,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GradientButton(
                                onTap: _verifyRecoveryKey,
                                text: "Verify",
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20)
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
