import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/password_entry_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

import 'common/fabCreateAccount.dart';

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({Key key}) : super(key: key);

  @override
  _RecoveryPageState createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final _recoveryKey = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      floatingActionButton: FABCreateAccount(
          isKeypadOpen: false,
          isFormValid: _recoveryKey.text.isNotEmpty,
          buttonText: 'Recover',
          onPressedFunction: () async {
            final dialog = createProgressDialog(context, "decrypting...");
            await dialog.show();
            try {
              await Configuration.instance.recover(_recoveryKey.text.trim());
              await dialog.hide();
              showToast("recovery successful!");
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: PasswordEntryPage(
                        mode: PasswordEntryMode.reset,
                      ),
                    );
                  },
                ),
              );
            } catch (e) {
              await dialog.hide();
              String errMessage = 'the recovery key you entered is incorrect';
              if (e is AssertionError) {
                errMessage = '$errMessage : ${e.message}';
              }
              showErrorDialog(context, "incorrect recovery key", errMessage);
            }
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  child: Text('Forgot Password',
                      style: Theme.of(context).textTheme.headline4),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      hintText: "enter your recovery key",
                      contentPadding: EdgeInsets.all(20),
                      border: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    style: TextStyle(
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
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        showErrorDialog(
                          context,
                          "sorry",
                          "due to the nature of our end-to-end encryption protocol, your data cannot be decrypted without your password or recovery key",
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Text(
                            "no recovery key?",
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1
                                .copyWith(
                                    fontSize: 14,
                                    decoration: TextDecoration.underline),
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
