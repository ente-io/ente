import "dart:async";
import 'dart:io';

import 'package:dots_indicator/dots_indicator.dart';
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import "package:photos/app.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/ui/account/email_entry_page.dart';
import 'package:photos/ui/account/login_page.dart';
import 'package:photos/ui/account/password_entry_page.dart';
import 'package:photos/ui/account/password_reentry_page.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/payment/subscription.dart';
import "package:photos/ui/settings/developer_settings_page.dart";
import "package:photos/ui/settings/developer_settings_widget.dart";
import "package:photos/ui/settings/language_picker.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

class LandingPageWidget extends StatefulWidget {
  const LandingPageWidget({super.key});

  @override
  State<LandingPageWidget> createState() => _LandingPageWidgetState();
}

class _LandingPageWidgetState extends State<LandingPageWidget> {
  static const kDeveloperModeTapCountThreshold = 7;

  double _featureIndex = 0;
  int _developerModeTapCount = 0;

  @override
  void initState() {
    super.initState();
    Future(_showAutoLogoutDialogIfRequired);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () async {
          _developerModeTapCount++;
          if (_developerModeTapCount >= kDeveloperModeTapCountThreshold) {
            _developerModeTapCount = 0;
            final result = await showChoiceDialog(
              context,
              title: S.of(context).developerSettings,
              firstButtonLabel: S.of(context).yes,
              body: S.of(context).developerSettingsWarning,
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
        },
        child: _getBody(),
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _getBody() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            kDebugMode
                ? GestureDetector(
                    child: const Align(
                      alignment: Alignment.topRight,
                      child: Text("Lang"),
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
                            unawaited(S.delegate.load(locale));
                          },
                          locale,
                        ),
                      ).then((value) {
                        setState(() {});
                      });
                    },
                  )
                : const SizedBox(),
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
                  key: const ValueKey("signInButton"),
                  style:
                      Theme.of(context).colorScheme.optionalActionButtonStyle,
                  onPressed: _navigateToSignInPage,
                  child: Text(
                    S.of(context).existingUser,
                    style: const TextStyle(
                      color: Colors.black, // same for both themes
                    ),
                  ),
                ),
              ),
            ),
            // const DeveloperSettingsWidget() does not refresh when the endpoint is changed
            // ignore: prefer_const_constructors
            DeveloperSettingsWidget(),
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
        text: S.of(context).newToEnte,
      ),
    );
  }

  Widget _getFeatureSlider() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: PageView(
        children: [
          FeatureItemWidget(
            "assets/onboarding_lock.png",
            S.of(context).privateBackups,
            S.of(context).forYourMemories,
            S.of(context).endtoendEncryptedByDefault,
          ),
          FeatureItemWidget(
            "assets/onboarding_safe.png",
            S.of(context).safelyStored,
            S.of(context).atAFalloutShelter,
            S.of(context).designedToOutlive,
          ),
          FeatureItemWidget(
            "assets/onboarding_sync.png",
            S.of(context).available,
            S.of(context).everywhere,
            Platform.isAndroid
                ? S.of(context).androidIosWebDesktop
                : S.of(context).mobileWebDesktop,
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
        title: S.of(context).pleaseLoginAgain,
        body: S.of(context).autoLogoutMessage,
        buttons: [
          ButtonWidget(
            buttonType: ButtonType.neutral,
            buttonAction: ButtonAction.first,
            labelText: S.of(context).ok,
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
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Padding(padding: EdgeInsets.all(2)),
            Text(
              featureTitleSecondLine,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Padding(padding: EdgeInsets.all(12)),
            Text(
              subText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
