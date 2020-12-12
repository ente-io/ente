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
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            "preserve your memories",
            style: TextStyle(
              fontSize: 16,
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
    );
  }
}
