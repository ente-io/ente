import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/email_entry_page.dart';
import 'package:photos/ui/login_page.dart';
import 'package:photos/ui/password_entry_page.dart';
import 'package:photos/ui/password_reentry_page.dart';
import 'package:photos/ui/subscription_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  double _featureIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _getBody(), resizeToAvoidBottomInset: false);
  }

  Widget _getBody() {
    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Container(
        padding: EdgeInsets.fromLTRB(8, 40, 8, 8),
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
              padding: EdgeInsets.all(24),
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
              padding: EdgeInsets.all(28),
            ),
            _getSignUpButton(context),
            Padding(
              padding: EdgeInsets.all(4),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Hero(
                    tag: "sign_in",
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        "sign in",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              onTap: _navigateToSignInPage,
            ),
            Padding(
              padding: EdgeInsets.all(4),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).buttonColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Container _getSignUpButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 80, right: 80),
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.fromLTRB(50, 16, 50, 16),
          side: BorderSide(
            width: 2,
            color: Theme.of(context).buttonColor,
          ),
        ),
        child: Hero(
          tag: "sign_up",
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              "sign up",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        onPressed: _navigateToSignUpPage,
      ),
    );
  }

  Widget _getFeatureSlider() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 320),
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
          Padding(padding: EdgeInsets.all(16)),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "protected",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).buttonColor,
                  ),
                ),
                Padding(padding: EdgeInsets.all(12)),
                Container(
                  child: Text(
                    "end-to-end encrypted with your password,",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.all(2)),
                Container(
                  child: Text(
                    "visible only to you",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
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
