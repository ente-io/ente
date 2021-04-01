import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/password_entry_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

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
        title: Text(
          "recover account",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: "enter your recovery key",
                contentPadding: EdgeInsets.all(20),
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
          Padding(padding: EdgeInsets.all(12)),
          Container(
            padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
            width: double.infinity,
            height: 64,
            child: button(
              "recover",
              fontSize: 18,
              onPressed: _recoveryKey.text.isNotEmpty
                  ? () async {
                      final dialog =
                          createProgressDialog(context, "decrypting...");
                      await dialog.show();
                      try {
                        await Configuration.instance
                            .recover(_recoveryKey.text.trim());
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
                        showErrorDialog(context, "incorrect recovery key",
                            "the recovery key you entered is incorrect");
                      }
                    }
                  : null,
            ),
          ),
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
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  "no recovery key?",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
