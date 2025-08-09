import 'dart:async';
import 'dart:io';

import 'package:ente_accounts/pages/email_entry_page.dart';
import 'package:ente_accounts/pages/login_page.dart';
import 'package:ente_accounts/pages/password_entry_page.dart';
import 'package:ente_accounts/pages/password_reentry_page.dart';
import 'package:ente_auth/app/view/app.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/events/trigger_logout_event.dart';
import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/locale.dart';
import 'package:ente_auth/theme/text_style.dart';
import 'package:ente_auth/ui/account/logout_dialog.dart';
import 'package:ente_auth/ui/common/gradient_button.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/models/button_result.dart';
import 'package:ente_auth/ui/home_page.dart';
import 'package:ente_auth/ui/settings/developer_settings_page.dart';
import 'package:ente_auth/ui/settings/developer_settings_widget.dart';
import 'package:ente_auth/ui/settings/language_picker.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/navigation_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_events/event_bus.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:local_auth/local_auth.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const kDeveloperModeTapCountThreshold = 7;

  late StreamSubscription<TriggerLogoutEvent> _triggerLogoutEvent;

  int _developerModeTapCount = 0;

  @override
  void initState() {
    _triggerLogoutEvent =
        Bus.instance.on<TriggerLogoutEvent>().listen((event) async {
      await autoLogoutAlert(context);
    });
    super.initState();
  }

  @override
  void dispose() {
    _triggerLogoutEvent.cancel();
    super.dispose();
  }

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
                      return const DeveloperSettingsPage();
                    },
                  ),
                );
                setState(() {});
              }
            }
          },
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                  maxWidth: 450,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40.0,
                    horizontal: 40,
                  ),
                  child: Column(
                    children: [
                      Column(
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
                                          App.setLocale(context, locale);
                                        },
                                        locale,
                                      ),
                                    ).then((value) {
                                      setState(() {});
                                    });
                                  },
                                )
                              : const SizedBox(),
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
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            l10n.onBoardingBody,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 20, bottom: 20),
                        child: GestureDetector(
                          onTap: _optForOfflineMode,
                          child: Center(
                            child: Text(
                              l10n.useOffline,
                              textAlign: TextAlign.center,
                              style: body.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .mutedTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const DeveloperSettingsWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _optForOfflineMode() async {
    bool canCheckBio = Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isWindows ||
        await LocalAuthentication().canCheckBiometrics;
    if (!canCheckBio) {
      showToast(
        context,
        "Sorry, biometric authentication is not supported on this device.",
      );
      return;
    }
    final bool hasOptedBefore = Configuration.instance.hasOptedForOfflineMode();
    ButtonResult? result;
    if (!hasOptedBefore) {
      result = await showChoiceActionSheet(
        context,
        title: context.l10n.warning,
        body: context.l10n.offlineModeWarning,
        secondButtonLabel: context.l10n.cancel,
        firstButtonLabel: context.l10n.ok,
      );
    }
    if (hasOptedBefore || result?.action == ButtonAction.first) {
      await Configuration.instance.optForOfflineMode();
      // ignore: unawaited_futures
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return const HomePage();
          },
        ),
      );
    }
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
