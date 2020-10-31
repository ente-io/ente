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
  TextEditingController _emailController;
  TextEditingController _nameController;

  @override
  void initState() {
    _emailController = TextEditingController(text: _config.getEmail());
    _nameController = TextEditingController(text: _config.getName());
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
                hintText: 'Full Name',
                contentPadding: EdgeInsets.all(20),
              ),
              controller: _nameController,
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.name,
            ),
            Padding(padding: EdgeInsets.all(12)),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'you@email.com',
                contentPadding: EdgeInsets.all(20),
              ),
              controller: _emailController,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
            ),
            Padding(padding: EdgeInsets.all(8)),
            Container(
              width: double.infinity,
              height: 44,
              child: button("Sign In", onPressed: () {
                final email = _emailController.text;
                if (!isValidEmail(email)) {
                  showErrorDialog(context, "Invalid email address",
                      "Please enter a valid email address.");
                  return;
                }
                _config.setEmail(email);
                _config.setName(_nameController.text);
                UserService.instance.getOtt(context, email);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
