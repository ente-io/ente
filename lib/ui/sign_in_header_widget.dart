import 'dart:async';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/ui/email_entry_page.dart';
import 'package:photos/ui/login_page.dart';
import 'package:photos/ui/password_entry_page.dart';
import 'package:photos/ui/password_reentry_page.dart';
import 'package:photos/ui/subscription_page.dart';

class SignInHeader extends StatefulWidget {
  const SignInHeader({Key key}) : super(key: key);

  @override
  _SignInHeaderState createState() => _SignInHeaderState();
}

class _SignInHeaderState extends State<SignInHeader> {
  StreamSubscription _userAuthEventSubscription;
  double _featureIndex = 0;

  @override
  void initState() {
    _userAuthEventSubscription =
        Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
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
    var hasConfiguredAccount = Configuration.instance.hasConfiguredAccount();
    var hasSubscription = BillingService.instance.getSubscription() != null;
    if (hasConfiguredAccount && hasSubscription) {
      return Container();
    } else {
      return _getBody(context);
    }
  }

  Widget _getBody(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 24, 8, 8),
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
            padding: EdgeInsets.all(2),
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
            padding: EdgeInsets.all(18),
          ),
          _getFeatureSlider(),
          new DotsIndicator(
            dotsCount: 3,
            position: _featureIndex,
            decorator: DotsDecorator(
              color: Colors.white24, // Inactive color
              activeColor: Theme.of(context).buttonColor,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
          ),
          _getSignUpButton(context),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text(
                  "sign in",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).buttonColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return LoginPage();
                  },
                ),
              );
            },
          ),
          Divider(
            height: 4,
            color: Theme.of(context).buttonColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Container _getSignUpButton(BuildContext context) {
    return Container(
      width: 340,
      height: 54,
      padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
      child: RaisedButton(
        child: Text(
          "sign up",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
        onPressed: () {
          var page;
          if (Configuration.instance.getToken() == null) {
            page = EmailEntryPage();
          } else {
            // No key
            if (Configuration.instance.getKeyAttributes() == null) {
              // Never had a key
              page = PasswordEntryPage();
            } else if (Configuration.instance.getKey() == null) {
              // Yet to decrypt the key
              page = PasswordReentryPage();
            } else {
              // All is well, user just has not subscribed
              page = SubscriptionPage(isOnboarding: true);
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  ConstrainedBox _getFeatureSlider() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 290,
      ),
      child: PageView(
        children: [
          _getProtectedFeature(),
          _getPreservedFeature(),
          _getAccessibleFeature(),
        ],
        onPageChanged: (index) {
          setState(() {
            _featureIndex = double.parse(index.toString());
          });
        },
      ),
    );
  }

  Widget _getProtectedFeature() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            "assets/protected.png",
            height: 170,
          ),
          Padding(padding: EdgeInsets.all(10)),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "protected",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(padding: EdgeInsets.all(6)),
                Container(
                  child: Text(
                    "encrypted by your master key,",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(2)),
                Container(
                  child: Text(
                    "only visible to you",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPreservedFeature() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            "assets/protected.png",
            height: 170,
          ),
          Padding(padding: EdgeInsets.all(10)),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "preserved",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(padding: EdgeInsets.all(6)),
                Container(
                  child: Text(
                    "reliably saved to multiple locations,",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(2)),
                Container(
                  child: Text(
                    "including a fallout shelter",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getAccessibleFeature() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(
            "assets/protected.png",
            height: 170,
          ),
          Padding(padding: EdgeInsets.all(10)),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "accessible",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Padding(padding: EdgeInsets.all(6)),
                Container(
                  child: Text(
                    "available on all your devices,",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: EdgeInsets.all(2)),
          Container(
            child: Text(
              "android, ios and desktop",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSignUpPage() {
    var page;
    if (Configuration.instance.getToken() == null) {
      page = EmailEntryPage();
    } else {
      // No key
      if (Configuration.instance.getKeyAttributes() == null) {
        // Never had a key
        page = PasswordEntryPage();
      } else if (Configuration.instance.getKey() == null) {
        // Yet to decrypt the key
        page = PasswordReentryPage();
      } else {
        // All is well, user just has not subscribed
        page = SubscriptionPage(isOnboarding: true);
      }
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  void _navigateToSignInPage() {
    var page;
    if (Configuration.instance.getToken() == null) {
      page = LoginPage();
    } else {
      // No key
      if (Configuration.instance.getKeyAttributes() == null) {
        // Never had a key
        page = PasswordEntryPage();
      } else if (Configuration.instance.getKey() == null) {
        // Yet to decrypt the key
        page = PasswordReentryPage();
      } else {
        // All is well, user just has not subscribed
        page = SubscriptionPage(isOnboarding: true);
      }
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }
}
