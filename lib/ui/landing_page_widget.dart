import 'dart:io';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/ui/common/gradientButton.dart';
import 'package:photos/ui/email_entry_page.dart';
import 'package:photos/ui/login_page.dart';
import 'package:photos/ui/password_entry_page.dart';
import 'package:photos/ui/password_reentry_page.dart';
import 'package:photos/ui/payment/subscription.dart';

class LandingPageWidget extends StatefulWidget {
  const LandingPageWidget({Key key}) : super(key: key);

  @override
  _LandingPageWidgetState createState() => _LandingPageWidgetState();
}

class _LandingPageWidgetState extends State<LandingPageWidget> {
  double _featureIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _getBody(), resizeToAvoidBottomInset: false);
  }

  Widget _getBody() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(12)),
            Text(
              "ente",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                fontSize: 36,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24),
            ),
            _getFeatureSlider(),
            DotsIndicator(
              dotsCount: 3,
              position: _featureIndex,
              decorator: DotsDecorator(
                activeColor: Theme.of(context).buttonColor,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(28),
            ),
            _getSignUpButton(context),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Hero(
                tag: "log_in",
                child: ElevatedButton(
                  style:
                      Theme.of(context).colorScheme.optionalActionButtonStyle,
                  child: Text(
                    "Existing user",
                    style: TextStyle(
                      color: Colors.black, // same for both themes
                    ),
                  ),
                  onPressed: _navigateToSignInPage,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSignUpButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: GradientButton(
        child: Text(
          "New to ente",
          style: gradientButtonTextTheme(),
        ),
        linearGradientColors: const [
          Color(0xFF2CD267),
          Color(0xFF1DB954),
        ],
        onTap: _navigateToSignUpPage,
      ),
    );
  }

  Widget _getFeatureSlider() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 320),
      child: PageView(
        children: [
          FeatureItemWidget(
            "assets/protected.png",
            "Private backups",
            "for your memories",
            "end-to-end encrypted by default",
          ),
          FeatureItemWidget(
            "assets/preserved.png",
            "Safely stored",
            "at a fallout shelter",
            "designed to outlive",
          ),
          FeatureItemWidget(
            "assets/synced.png",
            "Available",
            "everywhere",
            Platform.isAndroid
                ? "android, ios, web, desktop"
                : "ios, android, web, desktop",
          ),
        ],
        onPageChanged: (index) {
          setState(() {
            _featureIndex = double.parse(index.toString());
          });
        },
      ),
    );
  }

  void _navigateToSignUpPage() {
    Widget page;
    if (Configuration.instance.getEncryptedToken() == null) {
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
        page = getSubscriptionPage(isOnBoarding: true);
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
    Widget page;
    if (Configuration.instance.getEncryptedToken() == null) {
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
        page = getSubscriptionPage(isOnBoarding: true);
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

class FeatureItemWidget extends StatelessWidget {
  final String assetPath,
      featureTitleFirstLine,
      featureTitleSecondLine,
      subText;

  const FeatureItemWidget(
    this.assetPath,
    this.featureTitleFirstLine,
    this.featureTitleSecondLine,
    this.subText, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          assetPath,
          height: 160,
        ),
        Padding(padding: EdgeInsets.all(16)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              featureTitleFirstLine,
              style: Theme.of(context).textTheme.headline5,
            ),
            Padding(padding: EdgeInsets.all(2)),
            Text(
              featureTitleSecondLine,
              style: Theme.of(context).textTheme.headline5,
            ),
            Padding(padding: EdgeInsets.all(12)),
            Text(
              subText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
