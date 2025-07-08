import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/account_configured_event.dart';
import 'package:photos/main.dart';
import 'package:photos/models/account/Account.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/account/user_service.dart';
import 'package:photos/ui/tabs/home_widget.dart';

final Logger _logger = Logger('LoadingPage');

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    _tryAutomatedLogin();
  }

  Future<void> _tryAutomatedLogin() async {
    final Account? account = accountNotifier.value;

    if (account == null || account.username.isEmpty || account.upToken.isEmpty) {
      _logger.severe("Invalid or missing account data. Cannot continue.");
      handleAutomatedLoginFailure();
      return;
    }

    try {
      _logger.info("Attempting headless login for ${account.username}");
      await UserService.instance.setEmail(account.username);
      Configuration.instance.resetVolatilePassword();

      final String? enteToken = await UserService.instance.sendOttForAutomation(
        account.upToken,
        purpose: "login",
      );

      if (enteToken == null || enteToken.isEmpty) {
        _logger.warning("sendOttForAutomation returned null or empty token. Triggering registration.");
        final success = await _handleUnregisteredUser(account);
        if (!success) {
          handleAutomatedLoginFailure();
        }
        return;
      }

      await Configuration.instance.setToken(enteToken);

      _logger.info("Fetching user details...");
      final UserDetails userDetails = await UserService.instance.getUserDetailsV2(shouldCache: true);
      _logger.info("User authenticated: ${userDetails.email}");

      Bus.instance.fire(AccountConfiguredEvent());

      // Navigate to the HomeWidget and remove splash/login routes
      if (mounted) {
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeWidget()),
              (_) => false,
        );
      }
    } catch (e, s) {
      _logger.severe("Automated login failed", e, s);
      handleAutomatedLoginFailure();
    }
  }

  Future<bool> _handleUnregisteredUser(Account account) async {
    _logger.warning("User ${account.username} not registered. Starting registration (stub).");
    // TODO: implement automated SRP registration flow
    return false;
  }

  void handleAutomatedLoginFailure() {
    _logger.severe("Automated login failed. Exiting or fallback not implemented yet.");
    // TODO: implement fallback UI or exit app
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              "Please wait while logging in...",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
