import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';

class EmailEntryPage extends StatefulWidget {
  EmailEntryPage({Key key}) : super(key: key);

  @override
  _EmailEntryPageState createState() => _EmailEntryPageState();
}

class _EmailEntryPageState extends State<EmailEntryPage> {
  final _config = Configuration.instance;
  String _email;
  String _name;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Image.asset(
              "assets/welcome.png",
              width: 300,
              height: 200,
            ),
            Padding(padding: EdgeInsets.all(12)),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'your name',
                contentPadding: EdgeInsets.all(12),
              ),
              onChanged: (value) {
                setState(() {
                  _name = value;
                });
              },
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              initialValue: _config.getName(),
            ),
            Padding(padding: EdgeInsets.all(8)),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'you@email.com',
                contentPadding: EdgeInsets.all(12),
              ),
              onChanged: (value) {
                setState(() {
                  _email = value;
                });
              },
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              initialValue: _config.getEmail(),
            ),
            Padding(padding: EdgeInsets.all(12)),
            Container(
              width: double.infinity,
              height: 44,
              child: button("Sign In", onPressed: () {
                if (!isValidEmail(_email)) {
                  showErrorDialog(context, "Invalid email address",
                      "Please enter a valid email address.");
                  return;
                }
                _config.setEmail(_email);
                _config.setName(_name);
                UserService.instance.getOtt(context, _email);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
