import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/ott_verification_page.dart';
import 'package:photos/utils/dialog_util.dart';

class EmailEntryPage extends StatefulWidget {
  EmailEntryPage({Key key}) : super(key: key);

  @override
  _EmailEntryPageState createState() => _EmailEntryPageState();
}

class _EmailEntryPageState extends State<EmailEntryPage> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Preserve Memories"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
              hintText: 'email@domain.com',
              contentPadding: EdgeInsets.all(20),
            ),
            controller: _emailController,
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
          ),
          Padding(padding: EdgeInsets.all(8)),
          SizedBox(
              width: double.infinity,
              child: RaisedButton(
                onPressed: () {
                  _getOtt(_emailController.text);
                },
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                child: Text("Sign In"),
                color: Colors.pink[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _getOtt(String email) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    await Dio()
        .get(Configuration.instance.getHttpEndpoint() + "/users/ott",
            queryParameters: {
              "email": email,
            },
            options: Options(
              headers: {
                "X-Auth-Token": Configuration.instance.getToken(),
              },
            ))
        .catchError((e) async {
      Logger("EmailEntryPage").severe(e);
      await dialog.hide();
      _showErrorDialog();
    }).then((response) async {
      await dialog.hide();
      if (response.statusCode == 200) {
        _navigateToVerificationInstructionPage(email);
      } else {
        _showErrorDialog();
      }
    });
  }

  void _navigateToVerificationInstructionPage(String email) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return OTTVerificationPage(email);
        },
      ),
    );
  }

  _showErrorDialog() {
    AlertDialog alert = AlertDialog(
      title: Text("Oops."),
      content: Text("Sorry, something went wrong. Please try again."),
      actions: [
        FlatButton(
          child: Text("OK"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
