import "dart:async";

import "package:ente_components/ente_components.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
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
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/payment/subscription.dart';
import "package:photos/ui/settings/developer_settings_tap_area.dart";
import "package:photos/ui/settings/developer_settings_widget.dart";
import "package:photos/ui/settings/language_picker.dart";
import 'package:photos/ui/tabs/home_widget.dart';
import "package:rive/rive.dart" as rive;

class LandingPageWidget extends StatefulWidget {
  const LandingPageWidget({super.key});

  @override
  State<LandingPageWidget> createState() => _LandingPageWidgetState();
}

class _LandingPageWidgetState extends State<LandingPageWidget> {
  late final rive.FileLoader _onboardingAnimationLoader;

  @override
  void initState() {
    super.initState();
    _onboardingAnimationLoader = rive.FileLoader.fromAsset(
      "assets/onboarding.riv",
      riveFactory: rive.Factory.flutter,
    );
    Future(_showAutoLogoutDialogIfRequired);
    if (mounted) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  void dispose() {
    _onboardingAnimationLoader.dispose();
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    final lightComponentTheme = ComponentTheme.lightTheme(
      app: ComponentApp.photos,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.greenBase,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: colorScheme.greenBase,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: const SizedBox(),
      ),
      backgroundColor: colorScheme.greenBase,
      body: SafeArea(
        child: DeveloperSettingsTapArea(
          onSettingsChanged: () {
            setState(() {});
          },
          child: Column(
            children: [
              if (kDebugMode) _buildDebugLanguageButton(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildOnboardingAnimation(),
                      Text(
                        AppLocalizations.of(context).onboardingTitle,
                        textAlign: .center,
                        style: const TextStyle(
                          fontWeight: .w800,
                          fontFamily: TextStyles.outfitFontFamily,
                          fontSize: 36,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).onboardingDesc,
                        textAlign: .center,
                        style: textTheme.body.copyWith(
                          color: colorScheme.greenLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Theme(
                      data: lightComponentTheme,
                      child: ButtonComponent(
                        variant: ButtonComponentVariant.neutral,
                        label: AppLocalizations.of(context).createAnEnteAccount,
                        onTap: _navigateToSignUpPage,
                        shouldSurfaceExecutionStates: false,
                      ),
                    ),
                    if (localSettings.showLocalGalleryModeOption) ...[
                      const SizedBox(height: 12),
                      Theme(
                        data: lightComponentTheme,
                        child: ButtonComponent(
                          variant: ButtonComponentVariant.secondary,
                          label: AppLocalizations.of(
                            context,
                          ).continueWithoutAccount,
                          onTap: _navigateWithoutAccount,
                          shouldSurfaceExecutionStates: false,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _navigateToSignInPage,
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

  Widget _buildOnboardingAnimation() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      child: rive.RiveWidgetBuilder(
        fileLoader: _onboardingAnimationLoader,
        builder: (BuildContext context, rive.RiveState state) {
          if (state is rive.RiveLoaded) {
            return rive.RiveWidget(
              controller: state.controller,
              fit: rive.Fit.contain,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDebugLanguageButton() {
    return GestureDetector(
      child: const Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(right: 16),
          child: Text("Lang", style: TextStyle(color: Colors.black54)),
        ),
      ),
      onTap: () async {
        final locale = (await getLocale())!;
        unawaited(
          routeToPage(
            context,
            LanguageSelectorPage(appSupportedLocales, (locale) async {
              await setLocale(locale);
              EnteApp.setLocale(context, locale);
              unawaited(AppLocalizations.delegate.load(locale));
            }, locale),
          ).then((value) {
            setState(() {});
          }),
        );
      },
    );
  }

  Future<void> _navigateWithoutAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HomeWidget(startWithoutAccount: true),
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
        page = const PasswordEntryPage(mode: PasswordEntryMode.set);
      } else if (Configuration.instance.getKey() == null) {
        // Yet to decrypt the key
        page = const PasswordReentryPage();
      } else {
        // All is well, user just has not subscribed
        page = getSubscriptionPage(isOnBoarding: true);
      }
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return page;
          },
        ),
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
        page = const PasswordEntryPage(mode: PasswordEntryMode.set);
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
