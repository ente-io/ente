import 'dart:async';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:ente_accounts/pages/login_page.dart';
import 'package:ente_accounts/pages/password_entry_page.dart';
import 'package:ente_accounts/pages/password_reentry_page.dart';
import 'package:ente_ui/components/buttons/button_widget.dart';
import "package:ente_ui/pages/developer_settings_page.dart";
import "package:ente_ui/pages/web_page.dart";
import "package:ente_ui/theme/ente_theme.dart";
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/configuration.dart';
import "package:locker/ui/components/gradient_button.dart";
import "package:locker/ui/components/new_account_dialog.dart";
import 'package:locker/ui/pages/home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const kDeveloperModeTapCountThreshold = 7;
  static const _featureCount = 3;
  static const _autoScrollInterval = Duration(seconds: 4);

  late final PageController _pageController;
  Timer? _autoScrollTimer;

  int _developerModeTapCount = 0;
  int _activeDotIndex = 0;
  int _currentPage = 0;
  bool _autoScrollDisabled = false;

  @override
  void initState() {
    super.initState();
    const initialPage = _featureCount * 1000;
    _pageController = PageController(initialPage: initialPage);
    _pageController.addListener(_handlePageControllerScroll);
    _currentPage = initialPage;
    _activeDotIndex = _currentPage % _featureCount;
    _startAutoScroll();
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _pageController.removeListener(_handlePageControllerScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (_autoScrollDisabled) {
      return;
    }
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (!_pageController.hasClients) {
        return;
      }
      final nextPage = _currentPage + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _handlePageControllerScroll() {
    if (!_pageController.hasClients) {
      return;
    }
    if (_pageController.position.userScrollDirection != ScrollDirection.idle) {
      _autoScrollDisabled = true;
      _stopAutoScroll();
    }
  }

  void _animateToFeature(int index) {
    if (!_pageController.hasClients) {
      return;
    }
    final base = _currentPage - (_currentPage % _featureCount);
    final targetPage = base + index;
    if (targetPage == _currentPage) {
      return;
    }
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    debugPrint("Building OnboardingPage");
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colorScheme.primary700,
      appBar: AppBar(
        leading: const SizedBox(),
        title: Image.asset("assets/locker-logo.png", height: 24),
        backgroundColor: colorScheme.primary700,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _getFeatureSlider(context),
                          const SizedBox(height: 12),
                          DotsIndicator(
                            dotsCount: _featureCount,
                            position: _activeDotIndex,
                            animate: true,
                            animationDuration:
                                const Duration(milliseconds: 300),
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
                            onTap: _animateToFeature,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GradientButton(
                        text: l10n.loginToEnteAccount,
                        backgroundColor: Colors.white,
                        textColor: colorScheme.primary700,
                        onTap: _navigateToSignInPage,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          final result = await showCreateNewAccountDialog(
                            context,
                            title: l10n.unlockLockerNewUserTitle,
                            body: l10n.unlockLockerNewUserBody,
                            buttonLabel: l10n.checkoutEntePhotos,
                            assetPath: "assets/file_lock.png",
                          );

                          if (result?.action == ButtonAction.first) {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) {
                                  return WebPage(
                                    l10n.checkoutEntePhotos,
                                    "https://ente.io/",
                                  );
                                },
                              ),
                            );
                          }
                        },
                        child: Text(
                          l10n.noAccountCta,
                          style: getEnteTextTheme(context).bodyBold.copyWith(
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getFeatureSlider(BuildContext context) {
    final l10n = context.l10n;
    final features = [
      ("assets/onboarding_lock.png", l10n.featureSaveImportant),
      ("assets/onboarding_file.png", l10n.featurePassAutomatically),
      ("assets/onboarding_share.png", l10n.featureShareAnytime),
    ];

    return SizedBox(
      height: 320,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final feature = features[index % features.length];
          return FeatureItemWidget(
            feature.$1,
            feature.$2,
          );
        },
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
            _activeDotIndex = index % _featureCount;
          });
          _startAutoScroll();
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

class FeatureItemWidget extends StatelessWidget {
  final String assetPath;
  final String featureTitleFirstLine;

  const FeatureItemWidget(
    this.assetPath,
    this.featureTitleFirstLine, {
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
            ],
          ),
        ),
      ],
    );
  }
}
