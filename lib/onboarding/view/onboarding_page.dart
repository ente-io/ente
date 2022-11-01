// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/ui/account/email_entry_page.dart';
import 'package:ente_auth/ui/account/login_page.dart';
import 'package:ente_auth/ui/account/password_entry_page.dart';
import 'package:ente_auth/ui/account/password_reentry_page.dart';
import 'package:ente_auth/ui/common/gradient_button.dart';
import 'package:ente_auth/ui/home_page.dart';
import "package:flutter/material.dart";

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  Widget build(BuildContext context) {
    debugPrint("Building OnboardingPage");
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints.tightFor(height: 800, width: 450),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 40.0, horizontal: 40),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Image.asset(
                          "assets/sheild-front-gradient.png",
                          width: 200,
                          height: 200,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "ente",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            fontSize: 42,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Authenticator",
                          style: Theme.of(context).textTheme.headline4,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.onBoardingBody,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.headline6!.copyWith(
                                    color: Colors.white38,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GradientButton(
                        onTap: _navigateToSignUpPage,
                        text: l10n.newUser,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      child: Hero(
                        tag: "log_in",
                        child: ElevatedButton(
                          style: Theme.of(context)
                              .colorScheme
                              .optionalActionButtonStyle,
                          onPressed: _navigateToSignInPage,
                          child: Text(
                            l10n.existingUser,
                            style: const TextStyle(
                              color: Colors.black, // same for both themes
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSignUpPage() {
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
        page = const HomePage();
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
        // page = getSubscriptionPage(isOnBoarding: true);
        page = const HomePage();
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
