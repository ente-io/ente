import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
            Text.rich(
              TextSpan(
                children: const <TextSpan>[
                  TextSpan(
                    text: "With ",
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
                children: const <TextSpan>[
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
        children: const [
          FeatureItemWidget(
              "assets/protected.png",
              "Protected",
              "End-to-end encrypted with your password,",
              "visible only to you"),
          FeatureItemWidget("assets/synced.png", "Synced",
              "Available across all your devices,", "web, android and ios"),
          FeatureItemWidget(
              "assets/preserved.png",
              "Preserved",
              "Reliably replicated to a fallout shelter,",
              "designed to outlive"),
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
  final String assetPath, featureTitle, firstLine, secondLine;
  const FeatureItemWidget(
    this.assetPath,
    this.featureTitle,
    this.firstLine,
    this.secondLine, {
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
              featureTitle,
              style: Theme.of(context).textTheme.headline6,
            ),
            Padding(padding: EdgeInsets.all(12)),
            Text(
              firstLine,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
            Padding(padding: EdgeInsets.all(2)),
            Text(
              secondLine,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
