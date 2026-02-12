import "dart:async";

import 'package:dots_indicator/dots_indicator.dart';
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import "package:photos/app.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/account/email_entry_page.dart';
import 'package:photos/ui/account/login_page.dart';
import 'package:photos/ui/account/password_entry_page.dart';
import 'package:photos/ui/account/password_reentry_page.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/buttons/button_widget_v2.dart';
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/payment/subscription.dart';
import "package:photos/ui/settings/developer_settings_page.dart";
import "package:photos/ui/settings/developer_settings_widget.dart";
import "package:photos/ui/settings/language_picker.dart";
import 'package:photos/ui/tabs/home_widget.dart';
import "package:photos/utils/dialog_util.dart";

class LandingPageWidget extends StatefulWidget {
  const LandingPageWidget({super.key});

  @override
  State<LandingPageWidget> createState() => _LandingPageWidgetState();
}

class _LandingPageWidgetState extends State<LandingPageWidget> {
  static const kDeveloperModeTapCountThreshold = 7;
  static const _featureCount = 3;
  static const _autoScrollInterval = Duration(seconds: 4);

  int _currentPage = 0;
  int _activeDotIndex = 0;
  int _developerModeTapCount = 0;
  bool _autoScrollDisabled = false;
  Timer? _autoScrollTimer;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    const initialPage = _featureCount * 1000;
    _pageController = PageController(initialPage: initialPage);
    _pageController.addListener(_handlePageControllerScroll);
    _currentPage = initialPage;
    _activeDotIndex = _currentPage % _featureCount;
    _startAutoScroll();
    Future(_showAutoLogoutDialogIfRequired);
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _pageController.removeListener(_handlePageControllerScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (_autoScrollDisabled) return;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (!_pageController.hasClients) return;
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
    if (!_pageController.hasClients) return;
    if (_pageController.position.userScrollDirection != ScrollDirection.idle) {
      _autoScrollDisabled = true;
      _stopAutoScroll();
    }
  }

  void _animateToFeature(int index) {
    if (!_pageController.hasClients) return;
    final base = _currentPage - (_currentPage % _featureCount);
    final targetPage = base + index;
    if (targetPage == _currentPage) return;
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.greenBase,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: colorScheme.greenBase,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: const SizedBox(),
        title: Text(
          "ente",
          style: textTheme.h3Bold.copyWith(
            fontFamily: "Montserrat",
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: colorScheme.greenBase,
      body: SafeArea(
        child: GestureDetector(
          onTap: _handleDeveloperModeTap,
          child: Column(
            children: [
              if (kDebugMode) _buildDebugLanguageButton(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeatureCarousel(),
                    const SizedBox(height: 20),
                    _buildPageIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ButtonWidgetV2(
                      buttonType: ButtonTypeV2.neutral,
                      labelText:
                          AppLocalizations.of(context).createAnEnteAccount,
                      onTap: _navigateToSignUpPage,
                      shouldSurfaceExecutionStates: false,
                      shouldStickToLightTheme: true,
                    ),
                    if (localSettings.showOfflineModeOption) ...[
                      const SizedBox(height: 12),
                      ButtonWidgetV2(
                        buttonType: ButtonTypeV2.secondary,
                        labelText:
                            AppLocalizations.of(context).continueWithoutAccount,
                        onTap: _navigateWithoutAccount,
                        shouldSurfaceExecutionStates: false,
                        shouldStickToLightTheme: true,
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        _navigateToSignInPage();
                      },
                      child: Text(
                        AppLocalizations.of(context).loginToExistingAccount,
                        style: textTheme.body.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const DeveloperSettingsWidget(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugLanguageButton() {
    return GestureDetector(
      child: const Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(right: 16),
          child: Text(
            "Lang",
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
      onTap: () async {
        final locale = (await getLocale())!;
        // ignore: unawaited_futures
        routeToPage(
          context,
          LanguageSelectorPage(
            appSupportedLocales,
            (locale) async {
              await setLocale(locale);
              EnteApp.setLocale(context, locale);
              unawaited(AppLocalizations.delegate.load(locale));
            },
            locale,
          ),
        ).then((value) {
          setState(() {});
        });
      },
    );
  }

  Widget _buildFeatureCarousel() {
    final l10n = AppLocalizations.of(context);
    final features = [
      (
        "assets/onboarding_lock.png",
        l10n.searchAndDiscover,
        "",
        l10n.searchAndDiscoverDesc,
      ),
      (
        "assets/onboarding_safe.png",
        l10n.shareYourMemories,
        "",
        l10n.shareYourMemoriesDesc,
      ),
      (
        "assets/onboarding_sync.png",
        l10n.privateAndSecureBackups,
        "",
        l10n.privateAndSecureBackupsDesc,
      ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final feature = features[index % features.length];
          return FeatureItemWidget(
            feature.$1,
            feature.$2,
            feature.$3,
            feature.$4,
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

  Widget _buildPageIndicator() {
    const activeColor = Color.fromRGBO(33, 144, 50, 1);
    final inactiveColor = Colors.white.withValues(alpha: 0.32);
    return DotsIndicator(
      dotsCount: _featureCount,
      position: _activeDotIndex.toDouble(),
      animate: true,
      animationDuration: const Duration(milliseconds: 300),
      decorator: DotsDecorator(
        activeColor: activeColor,
        color: inactiveColor,
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
    );
  }

  Future<void> _navigateWithoutAccount() async {
    updateService.hideChangeLog().ignore();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HomeWidget(startWithoutAccount: true),
      ),
    );
  }

  Future<void> _handleDeveloperModeTap() async {
    _developerModeTapCount++;
    if (_developerModeTapCount >= kDeveloperModeTapCountThreshold) {
      _developerModeTapCount = 0;
      final result = await showChoiceDialog(
        context,
        title: AppLocalizations.of(context).developerSettings,
        firstButtonLabel: AppLocalizations.of(context).yes,
        body: AppLocalizations.of(context).developerSettingsWarning,
        isDismissible: false,
      );
      if (result?.action == ButtonAction.first) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return const DeveloperSettingsPage();
            },
          ),
        );
        setState(() {});
      }
    }
  }

  Future<void> _navigateToSignUpPage() async {
    updateService.hideChangeLog().ignore();
    Widget page;
    if (Configuration.instance.getEncryptedToken() == null) {
      page = const EmailEntryPage();
    } else {
      // No key
      if (Configuration.instance.getKeyAttributes() == null) {
        // Never had a key
        page = const PasswordEntryPage(
          mode: PasswordEntryMode.set,
        );
      } else if (Configuration.instance.getKey() == null) {
        // Yet to decrypt the key
        page = const PasswordReentryPage();
      } else {
        // All is well, user just has not subscribed
        page = getSubscriptionPage(isOnBoarding: true);
      }
    }
    // ignore: unawaited_futures
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  void _navigateToSignInPage() {
    updateService.hideChangeLog().ignore();
    Widget page;
    if (Configuration.instance.getEncryptedToken() == null) {
      page = const LoginPage();
    } else {
      // No key
      if (Configuration.instance.getKeyAttributes() == null) {
        // Never had a key
        page = const PasswordEntryPage(
          mode: PasswordEntryMode.set,
        );
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
      final result = await showDialogWidget(
        context: context,
        title: AppLocalizations.of(context).pleaseLoginAgain,
        body: AppLocalizations.of(context).autoLogoutMessage,
        buttons: [
          ButtonWidget(
            buttonType: ButtonType.neutral,
            buttonAction: ButtonAction.first,
            labelText: AppLocalizations.of(context).ok,
            isInAlert: true,
          ),
        ],
      );
      Configuration.instance.clearAutoLogoutFlag().ignore();
      if (result?.action != null && result!.action == ButtonAction.first) {
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontFamily: "Nunito",
      fontWeight: FontWeight.w800,
      fontSize: 24,
      letterSpacing: -1,
      color: Colors.white,
    );

    const subTextStyle = TextStyle(
      fontFamily: "Inter",
      fontWeight: FontWeight.w500,
      fontSize: 14,
      height: 20 / 14,
      color: Color(0xFFAAFFB8),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Image.asset(
          assetPath,
          height: 160,
        ),
        const Padding(padding: EdgeInsets.all(16)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              featureTitleFirstLine,
              style: titleStyle,
              textAlign: TextAlign.center,
            ),
            if (featureTitleSecondLine.isNotEmpty)
              Text(
                featureTitleSecondLine,
                style: titleStyle,
                textAlign: TextAlign.center,
              ),
            const Padding(padding: EdgeInsets.all(2)),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                subText,
                textAlign: TextAlign.center,
                style: subTextStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
