import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_configuration/base_configuration.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:ente_ui/components/buttons/dynamic_fab.dart';
import 'package:ente_ui/pages/base_home_page.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/material.dart';

class RecoveryPage extends StatefulWidget {
  final BaseConfiguration config;
  final BaseHomePage homePage;

  const RecoveryPage(this.config, this.homePage, {super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final _recoveryKey = TextEditingController();

  Future<void> onPressed() async {
    FocusScope.of(context).unfocus();
    final dialog = createProgressDialog(context, "Decrypting...");
    await dialog.show();
    try {
      await widget.config.recover(_recoveryKey.text.trim());
      await dialog.hide();
      showToast(context, "Recovery successful!");
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return PopScope(
              canPop: false,
              child: PasswordEntryPage(
                widget.config,
                PasswordEntryMode.reset,
                widget.homePage,
              ),
            );
          },
        ),
      );
    } catch (e) {
      await dialog.hide();
      String errMessage = 'The recovery key you entered is incorrect';
      if (e is AssertionError) {
        errMessage = '$errMessage : ${e.message}';
      }
      await showErrorDialog(context, "Incorrect recovery key", errMessage);
    }
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
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.backgroundBase,
        centerTitle: true,
        title: Image.asset(
          'assets/locker-logo-blue.png',
          height: 24,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colorScheme.primary700,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      floatingActionButton: DynamicFAB(
        isKeypadOpen: isKeypadOpen,
        isFormValid: _recoveryKey.text.isNotEmpty,
        buttonText: context.strings.recover,
        onPressedFunction: onPressed,
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        context.strings.recoveryKey,
                        style: textTheme.bodyBold.copyWith(
                          color: colorScheme.textBase,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: InputDecoration(
                          fillColor: colorScheme.backdropBase,
                          filled: true,
                          hintText: context.strings.enterRecoveryKeyHint,
                          hintStyle: TextStyle(color: colorScheme.textMuted),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: textTheme.body.copyWith(
                          color: colorScheme.textBase,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                        minLines: 4,
                        maxLines: 5,
                        controller: _recoveryKey,
                        autofocus: false,
                        autocorrect: false,
                        keyboardType: TextInputType.multiline,
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            showErrorDialog(
                              context,
                              "Sorry",
                              "Due to the nature of our end-to-end encryption protocol, your data cannot be decrypted without your password or recovery key",
                            );
                          },
                          child: Text(
                            context.strings.noRecoveryKeyTitle,
                            style: textTheme.body.copyWith(
                              color: colorScheme.primary700,
                              decoration: TextDecoration.underline,
                              decorationColor: colorScheme.primary700,
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
        ],
      ),
    );
  }
}
