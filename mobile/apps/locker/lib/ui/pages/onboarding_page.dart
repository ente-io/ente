import 'package:dots_indicator/dots_indicator.dart';
import 'package:ente_accounts/pages/password_entry_page.dart';
import 'package:ente_accounts/pages/password_reentry_page.dart';
import 'package:ente_ui/components/buttons/button_widget.dart';
import "package:ente_ui/pages/developer_settings_page.dart";
import "package:ente_ui/theme/ente_theme.dart";
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/configuration.dart';
import "package:locker/ui/components/new_account_dialog.dart";
import 'package:locker/ui/pages/home_page.dart';
import 'package:locker/ui/pages/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const kDeveloperModeTapCountThreshold = 7;

  double _featureIndex = 0;
  int _developerModeTapCount = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    debugPrint("Building OnboardingPage");
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colorScheme.primary700,
      body: GestureDetector(
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
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Padding(padding: EdgeInsets.all(12)),
                        const Text(
                          "Locker",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Padding(padding: EdgeInsets.all(28)),
                        _getFeatureSlider(),
                        const Padding(padding: EdgeInsets.all(12)),
                        DotsIndicator(
                          dotsCount: 3,
                          position: _featureIndex.toInt(),
                          decorator: DotsDecorator(
                            activeColor: Colors.white,
                            color: Colors.white.withValues(alpha: 0.32),
                            activeShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            size: const Size(10, 10),
                            activeSize: const Size(20, 10),
                            spacing: const EdgeInsets.all(6),
                          ),
                        ),
                        const Padding(padding: EdgeInsets.all(28)),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  onPressed: _navigateToSignInPage,
                  child: Text(
                    "Log in to your Ente account",
                    style: getEnteTextTheme(context).bodyBold.copyWith(
                          color: colorScheme.primary700,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    showCreateNewAccountDialog(
                      context,
                      title: "Unlock locker with a paid plan",
                      body:
                          "Locker is available only to Ente photos paid users. Upgrade to a paid plan from Photos to use Locker",
                      buttonLabel: "Checkout Ente Photos",
                      assetPath: "assets/file_lock.png",
                      icon: const SizedBox.shrink(),
                    );
                  },
                  child: Text(
                    "I don't have an account",
                    style: getEnteTextTheme(context).bodyBold.copyWith(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.all(20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getFeatureSlider() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: PageView(
        children: const [
          FeatureItemWidget(
            "assets/onboarding_lock.png",
            "Save your important",
            "documents and credentials",
          ),
          FeatureItemWidget(
            "assets/onboarding_file.png",
            "Pass them on automatically in",
            "emergencies",
          ),
          FeatureItemWidget(
            "assets/onboarding_share.png",
            "Share them anytime",
            "",
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

  void _navigateToSignInPage() {
    Widget page;
    if (Configuration.instance.getEncryptedToken() == null) {
      page = const LoginPage();
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

class FeatureItemWidget extends StatelessWidget {
  final String assetPath;
  final String featureTitleFirstLine;
  final String featureTitleSecondLine;

  const FeatureItemWidget(
    this.assetPath,
    this.featureTitleFirstLine,
    this.featureTitleSecondLine, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          assetPath,
          height: 200,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              featureTitleFirstLine,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const Padding(padding: EdgeInsets.all(2)),
            Text(
              featureTitleSecondLine,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}
