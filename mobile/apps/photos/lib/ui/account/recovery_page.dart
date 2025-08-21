import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/account/password_entry_page.dart';
import 'package:photos/ui/common/dynamic_fab.dart';
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/utils/dialog_util.dart';

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final _recoveryKey = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;
    final theme = Theme.of(context);
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
          color: theme.iconTheme.color,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      floatingActionButton: DynamicFAB(
        isKeypadOpen: isKeypadOpen,
        isFormValid: _recoveryKey.text.isNotEmpty,
        buttonText: S.of(context).recoverButton,
        onPressedFunction: () async {
          FocusScope.of(context).unfocus();
          final dialog =
              createProgressDialog(context, S.of(context).decrypting);
          await dialog.show();
          try {
            await Configuration.instance.recover(_recoveryKey.text.trim());
            await dialog.hide();
            showShortToast(context, S.of(context).recoverySuccessful);
            // ignore: unawaited_futures
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const PopScope(
                    canPop: false,
                    child: PasswordEntryPage(
                      mode: PasswordEntryMode.reset,
                    ),
                  );
                },
              ),
            );
          } catch (e) {
            await dialog.hide();
            String errMessage = S.of(context).incorrectRecoveryKeyBody;
            if (e is AssertionError) {
              errMessage = '$errMessage : ${e.message}';
            }
            // ignore: unawaited_futures
            showErrorDialog(
              context,
              S.of(context).incorrectRecoveryKeyTitle,
              errMessage,
            );
          }
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  child: Text(
                    S.of(context).forgotPassword,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: EnteTheme.getColorScheme(theme).fillFaint,
                      hintText: S.of(context).enterYourRecoveryKey,
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
                    controller: _recoveryKey,
                    autofocus: false,
                    autocorrect: false,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Divider(
                    thickness: 1,
                    color: EnteTheme.getColorScheme(theme).strokeFaint,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        showErrorDialog(
                          context,
                          S.of(context).sorry,
                          S.of(context).noRecoveryKeyNoDecryption,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Text(
                            S.of(context).noRecoveryKey,
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
