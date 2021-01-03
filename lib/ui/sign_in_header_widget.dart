import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/email_entry_page.dart';
import 'package:photos/ui/passphrase_entry_page.dart';
import 'package:photos/ui/passphrase_reentry_page.dart';

class SignInHeader extends StatefulWidget {
  const SignInHeader({Key key}) : super(key: key);

  @override
  _SignInHeaderState createState() => _SignInHeaderState();
}

class _SignInHeaderState extends State<SignInHeader> {
  StreamSubscription _userAuthEventSubscription;

  @override
  void initState() {
    _userAuthEventSubscription =
        Bus.instance.on<UserAuthenticatedEvent>().listen((event) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _userAuthEventSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Configuration.instance.hasConfiguredAccount()) {
      return Container();
    }
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Text.rich(
              TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: "with ",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: "ente",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: EdgeInsets.all(6),
            ),
            Text.rich(
              TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: "your ",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: "memories",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: " are",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: EdgeInsets.all(10),
            ),
            Card(
              child: ExpansionTile(
                title: Text('protected'),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                        'only visible to you as they are encrypted by your master key'),
                  ),
                ],
              ),
            ),
            Card(
              child: ExpansionTile(
                title: Text('preserved'),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                        'stored in multiple locations including an underground fallout shelter'),
                  ),
                ],
              ),
            ),
            Card(
              child: ExpansionTile(
                title: Text('accessible'),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text('accessible across all your devices'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
              child: Container(
                width: double.infinity,
                height: 64,
                child: button(
                  "sign in",
                  fontSize: 18,
                  onPressed: () {
                    var page;
                    if (Configuration.instance.getToken() == null) {
                      page = EmailEntryPage();
                    } else {
                      // No key
                      if (Configuration.instance.getKeyAttributes() != null) {
                        // Yet to set or decrypt the key
                        page = PassphraseReentryPage();
                      } else {
                        // Never had a key
                        page = PassphraseEntryPage();
                      }
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) {
                          return page;
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(padding: EdgeInsets.all(10)),
            Divider(
              height: 2,
            ),
          ],
        ),
      ),
    );
  }
}
