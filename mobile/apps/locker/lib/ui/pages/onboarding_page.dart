import 'package:ente_accounts/pages/email_entry_page.dart';
import 'package:ente_accounts/pages/login_page.dart';
import 'package:ente_accounts/pages/password_entry_page.dart';
import 'package:ente_accounts/pages/password_reentry_page.dart';
import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/components/buttons/gradient_button.dart';
import 'package:ente_ui/components/developer_settings_widget.dart';
import "package:ente_ui/pages/developer_settings_page.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/ente_theme_data.dart";
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/ui/pages/home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const kDeveloperModeTapCountThreshold = 7;

  int _developerModeTapCount = 0;

  @override
  Widget build(BuildContext context) {
    debugPrint("Building OnboardingPage");
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () async {
            _developerModeTapCount++;
            if (_developerModeTapCount >= kDeveloperModeTapCountThreshold) {
              _developerModeTapCount = 0;
              final result = await showChoiceDialog(
                context,
                title: l10n.developerSettings,
                firstButtonLabel: l10n.yes,
                body: l10n.developerSettingsWarning,
                isDismissible: false,
              );
              if (result?.action == ButtonAction.first) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return DeveloperSettingsPage(Configuration.instance);
                    },
                  ),
                );
                setState(() {});
              }
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: 450,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40.0,
                        horizontal: 40,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/locker.png",
                                  width: 200,
                                  height: 200,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "ente",
                                  style: getEnteTextTheme(context).h1.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Montserrat',
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Locker",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  l10n.onBoardingBody,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBoardingBodyColor,
                                      ),
                                ),
                              ],
                            ),
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
                          const SizedBox(height: 16),
                          Container(
                            height: 56,
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                          const SizedBox(height: 4),
                          DeveloperSettingsWidget(Configuration.instance),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToSignUpPage() {
    Widget page;
    if (Configuration.instance.getEncryptedToken() == null) {
      page = EmailEntryPage(Configuration.instance);
    } else {
      // No key
      if (Configuration.instance.getKeyAttributes() == null) {
        // Never had a key
        page = PasswordEntryPage(
          Configuration.instance,
          PasswordEntryMode.set,
          const HomePage(),
        );
      } else if (Configuration.instance.getKey() == null) {
        // Yet to decrypt the key
        page = PasswordReentryPage(
          Configuration.instance,
          const HomePage(),
        );
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
      page = LoginPage(Configuration.instance);
    } else {
      // No key
      if (Configuration.instance.getKeyAttributes() == null) {
        // Never had a key
        page = PasswordEntryPage(
          Configuration.instance,
          PasswordEntryMode.set,
          const HomePage(),
        );
      } else if (Configuration.instance.getKey() == null) {
        // Yet to decrypt the key
        page = PasswordReentryPage(
          Configuration.instance,
          const HomePage(),
        );
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
