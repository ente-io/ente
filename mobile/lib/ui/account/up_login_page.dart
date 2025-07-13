import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/account_configured_event.dart';
import 'package:photos/main.dart';
import 'package:photos/models/account/Account.dart';
import 'package:photos/models/api/user/key_attributes.dart';
import 'package:photos/models/api/user/srp.dart';
import 'package:photos/services/account/user_service.dart';
import 'package:photos/ui/tabs/home_widget.dart';

final Logger _logger = Logger('LoadingPage');

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool _isProcessing = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() => _attemptAutomatedLogin());
  }

  Future<void> _attemptAutomatedLogin() async {
    final Account? account = accountNotifier.value;
    _logger.info("account 3: user name: ${account?.username}, uptoken: X${account?.upToken}X, password: ${account?.servicePassword}");

    if (account == null ||
        account.username.isEmpty ||
        account.upToken.isEmpty ||
        account.servicePassword.isEmpty) {
      _logger.severe("Invalid or missing account data.");
      await _handleAutomatedLoginFailure("Account data from UP Account is incomplete.");
      return;
    }

    await Fluttertoast.showToast(msg: "Logging in...");

    try {
      _logger.info("Starting headless login for ${account.username}");

      await UserService.instance.setEmail(account.username);
      Configuration.instance.resetVolatilePassword();

      final SrpAttributes srp = await UserService.instance.getSrpAttributes(account.username);

      final keyAttributes = KeyAttributes(
          srp.kekSalt,
          '', '', '', '', '',
          srp.memLimit, srp.opsLimit,
          '', '', '', '',
      );

      final String? encryptedEnteToken = await UserService.instance.sendOttForAutomation(account.upToken, purpose: "login");

      if (encryptedEnteToken == null || encryptedEnteToken.isEmpty) {
        _logger.warning("sendOttForAutomation returned null or empty token.");
        await Fluttertoast.showToast(msg: "Login failed, trying registration...");
        await _attemptRegistration(account);
        return;
      }

      await Configuration.instance.setEncryptedToken(encryptedEnteToken);
      _logger.info("Encrypted token saved in configuration.");

      await Configuration.instance.decryptSecretsAndGetKeyEncKey(
        account.servicePassword,
        keyAttributes,
      );

      if (!Configuration.instance.hasConfiguredAccount() || Configuration.instance.getToken() == null) {
        _logger.severe("Token or configured account check failed after decryption.");
        throw Exception("Decryption succeeded but account setup failed.");
      }

      _logger.info("Login successful for ${Configuration.instance.getEmail()}");
      await Fluttertoast.showToast(msg: "Login successful");
      await _onLoginSuccess();
    } catch (e, s) {
      _logger.warning("Login failed — attempting fallback registration", e, s);
      await Fluttertoast.showToast(msg: "Login failed, trying registration...");
      await _attemptRegistration(account);
    }
  }

  Future<void> _attemptRegistration(Account account) async {
    try {
      _logger.info("Attempting fallback registration for ${account.username}");
      await Fluttertoast.showToast(msg: "Registering account...");

      await UserService.instance.setEmail(account.username);
      Configuration.instance.resetVolatilePassword();

      final String? encryptedEnteToken = await UserService.instance.sendOttForAutomation(account.upToken, purpose: "signup");
      _logger.info("entetoken $encryptedEnteToken");

      if (encryptedEnteToken == null || encryptedEnteToken.isEmpty) {
        _logger.info("UPACCOUNT 10");

        _logger.severe("sendOttForAutomation (register) returned empty.");
        await Fluttertoast.showToast(msg: "Registration failed");
        await _handleAutomatedLoginFailure("Failed to retrieve token for registration.");
        return;
      }

      await Configuration.instance.setEncryptedToken(encryptedEnteToken);
      _logger.info("Encrypted token set for registration flow.");

      final loginKey = Uint8List.fromList(utf8.encode(account.servicePassword));
      _logger.info("UPACCOUNT 0");

      await UserService.instance.registerOrUpdateSrp(loginKey);

      _logger.info("Registration via SRP succeeded.");

      final SrpAttributes srp = await UserService.instance.getSrpAttributes(account.username);

      final keyAttributes = KeyAttributes(
          srp.kekSalt,
          '', '', '', '', '',
          srp.memLimit, srp.opsLimit,
          '', '', '', '',
      );

      await Configuration.instance.decryptSecretsAndGetKeyEncKey(
        account.servicePassword,
        keyAttributes,
      );

      if (!Configuration.instance.hasConfiguredAccount() || Configuration.instance.getToken() == null) {
        _logger.severe("Account configuration failed after registration.");
        await Fluttertoast.showToast(msg: "Registration failed");
        await _handleAutomatedLoginFailure("Account setup incomplete after registration.");
        return;
      }

      _logger.info("Headless registration completed successfully.");
      await Fluttertoast.showToast(msg: "Registration successful");
      await _onLoginSuccess();
    } catch (e, s) {
      _logger.severe("Automated registration failed", e, s);
      await Fluttertoast.showToast(msg: "Registration failed");
      await _handleAutomatedLoginFailure("Automated registration failed.");
    }
  }

  Future<void> _onLoginSuccess() async {
    Bus.instance.fire(AccountConfiguredEvent());
    if (mounted) {
      setState(() => _isProcessing = false);
      await Future.delayed(const Duration(milliseconds: 300));
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeWidget()),
            (_) => false,
      );
    }
  }

  Future<void> _handleAutomatedLoginFailure(String message) async {
    _logger.warning("Login/Registration failed: $message");
    // Optional: show error or exit
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator(
          color: Colors.blue,
        )
            : const Text("Finished"),
      ),
    );
  }
}
