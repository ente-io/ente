import 'dart:io';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/services/user_remote_flag_service.dart';
import 'package:photos/ui/account/email_entry_page.dart';
import 'package:photos/ui/account/login_page.dart';
import 'package:photos/ui/account/password_entry_page.dart';
import 'package:photos/ui/account/password_reentry_page.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/payment/subscription.dart';

class LandingPageWidget extends StatefulWidget {
  const LandingPageWidget({Key? key}) : super(key: key);

  @override
  State<LandingPageWidget> createState() => _LandingPageWidgetState();
}

class _LandingPageWidgetState extends State<LandingPageWidget> {
  double _featureIndex = 0;

  @override
  void initState() {
    super.initState();
    Future(_showAutoLogoutDialogIfRequired);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _getBody(), resizeToAvoidBottomInset: false);
  }

  Widget _getBody() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(12)),
            const Text(
              "ente",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                fontSize: 42,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(28),
            ),
            _getFeatureSlider(),
            const Padding(
              padding: EdgeInsets.all(12),
            ),
            DotsIndicator(
              dotsCount: 3,
              position: _featureIndex,
              decorator: DotsDecorator(
                activeColor:
                    Theme.of(context).colorScheme.dotsIndicatorActiveColor,
                color: Theme.of(context).colorScheme.dotsIndicatorInactiveColor,
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                size: const Size(100, 5),
                activeSize: const Size(100, 5),
                spacing: const EdgeInsets.all(3),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(28),
            ),
            _getSignUpButton(context),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Hero(
                tag: "log_in",
                child: ElevatedButton(
                  style:
                      Theme.of(context).colorScheme.optionalActionButtonStyle,
                  onPressed: _navigateToSignInPage,
                  child: const Text(
                    "Existing user",
                    style: TextStyle(
                      color: Colors.black, // same for both themes
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GradientButton(
        onTap: _navigateToSignUpPage,
        text: "New to ente",
      ),
    );
  }

  Widget _getFeatureSlider() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: PageView(
        children: [
          const FeatureItemWidget(
            "assets/onboarding_lock.png",
            "Private backups",
            "for your memories",
            "End-to-end encrypted by default",
          ),
          const FeatureItemWidget(
            "assets/onboarding_safe.png",
            "Safely stored",
            "at a fallout shelter",
            "Designed to outlive",
          ),
          FeatureItemWidget(
            "assets/onboarding_sync.png",
            "Available",
            "everywhere",
            Platform.isAndroid
                ? "Android, iOS, Web, Desktop"
                : "Mobile, Web, Desktop",
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
    UpdateService.instance.hideChangeLog().ignore();
    UserRemoteFlagService.instance.stopPasswordReminder().ignore();
    Widget page;
    if (Configuration.instance.getEncryptedToken() == null) {
      page = const EmailEntryPage();
    } else {
      // No key
      if (Configuration.instance.getKeyAttributes() == null) {
        // Never had a key
        page = const PasswordEntryPage();
      } else if (Configuration.instance.getKey() == null) {
        // Yet to decrypt the key
        page = const PasswordReentryPage();
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
    UpdateService.instance.hideChangeLog().ignore();
    UserRemoteFlagService.instance.stopPasswordReminder().ignore();
    Widget page;
    if (Configuration.instance.getEncryptedToken() == null) {
      page = const LoginPage();
    } else {
      // No key
      if (Configuration.instance.getKeyAttributes() == null) {
        // Never had a key
        page = const PasswordEntryPage();
      } else if (Configuration.instance.getKey() == null) {
        // Yet to decrypt the key
        page = const PasswordReentryPage();
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

  Future<void> _showAutoLogoutDialogIfRequired() async {
    final bool autoLogout = Configuration.instance.showAutoLogoutDialog();
    if (autoLogout) {
      final result = await showChoiceDialog(
        context,
        "Please login again",
        '''Unfortunately, the ente app had to log you out because of some technical issues. Sorry!\n\nPlease login again.''',
        firstAction: "Cancel",
        secondAction: "Login",
      );
      if (result != null) {
        await Configuration.instance.clearAutoLogoutFlag();
      }
      if (result == DialogUserChoice.secondChoice) {
        _navigateToSignInPage();
      }
    }
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
    Key? key,
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
        const Padding(padding: EdgeInsets.all(16)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              featureTitleFirstLine,
              style: Theme.of(context).textTheme.headline5,
            ),
            const Padding(padding: EdgeInsets.all(2)),
            Text(
              featureTitleSecondLine,
              style: Theme.of(context).textTheme.headline5,
            ),
            const Padding(padding: EdgeInsets.all(12)),
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
