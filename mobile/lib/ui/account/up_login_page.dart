import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/account_configured_event.dart';
import 'package:photos/main.dart';
import 'package:photos/models/account/Account.dart';
import 'package:photos/models/api/user/key_attributes.dart';
import 'package:photos/models/api/user/key_gen_result.dart';
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
      _logger.info("c${account.username}");

      await UserService.instance.setEmail(account.username);
      Configuration.instance.resetVolatilePassword();

      // Try to get token first (this will fail if user doesn't exist)
      final response = await UserService.instance.sendOttForAutomation(account.upToken, purpose: "login");
     
      if (response == null) {
        _logger.warning("Login response is null.");
        await Fluttertoast.showToast(msg: "Login failed, trying registration...");
        await _attemptRegistration(account);
        return;
      }
      _logger.info("Received login response: $response");
      await _saveUpAutomationSession(response);
      _logger.info("Session config set for login flow.");

      // If keyAttributes are present, set them explicitly (even though _saveUpAutomationSession does it, this is for clarity/logging)
      if (response["keyAttributes"] != null) {
        await Configuration.instance.setKeyAttributes(KeyAttributes.fromMap(response["keyAttributes"]));
        _logger.info("Set key attributes from login response.");
      }

      // If SRP attributes are present (rare for login, but possible), set them
      if (response["srpSalt"] != null && response["srpVerifier"] != null) {
        final result = KeyGenResult(
          srpSalt: response["srpSalt"],
          srpVerifier: response["srpVerifier"],
          // Add other fields if present
        );
        await UserService.instance.setAttributes(result);
        _logger.info("Set SRP attributes from login response.");
      }

      // Use the saved keyAttributes from config for decryption
      final keyAttributes = Configuration.instance.getKeyAttributes();
      _logger.info("Loaded key attributes from config: $keyAttributes");
      if (keyAttributes == null) {
        throw Exception("No key attributes found after login.");
      }
      await Configuration.instance.decryptSecretsAndGetKeyEncKey(
        account.servicePassword,
        keyAttributes,
      );
      _logger.info("Decryption succeeded.");

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

      final response = await UserService.instance.sendOttForAutomation(account.upToken, purpose: "signup");
      if (response == null) {
        _logger.severe("sendOttForAutomation (register) returned empty.");
        await Fluttertoast.showToast(msg: "Registration failed");
        await _handleAutomatedLoginFailure("Failed to retrieve token for registration.");
        return;
      }
      if (response["token"] == null) {
        _logger.severe("sendOttForAutomation (register) returned null token.");
        await Fluttertoast.showToast(msg: "Registration failed");
        await _handleAutomatedLoginFailure("Failed to retrieve token for registration.");
        return;
      }

      await _saveUpAutomationSession(response);
      _logger.info("Session config set for registration flow.");

      // Generate keys and attributes as in the main branch
      final KeyGenResult result = await Configuration.instance.generateKey(account.servicePassword);
      await UserService.instance.setAttributes(result);

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

  Future<void> _saveUpAutomationSession(Map<String, dynamic> response) async {
    if (response["id"] != null) {
      await Configuration.instance.setUserID(response["id"]);
      _logger.info("Saved user ID: ${response["id"]}");
    }
    if (response["encryptedToken"] != null) {
      await Configuration.instance.setEncryptedToken(response["encryptedToken"]);
      _logger.info("Saved encrypted token.");
    } else if (response["enteToken"] != null) {
      await Configuration.instance.setEncryptedToken(response["enteToken"]);
      _logger.info("Saved enteToken as encrypted token.");
    } else if (response["token"] != null) {
      await Configuration.instance.setToken(response["token"]);
      _logger.info("Saved plain token.");
    }
    if (response["keyAttributes"] != null) {
      await Configuration.instance.setKeyAttributes(KeyAttributes.fromMap(response["keyAttributes"]));
      _logger.info("Saved key attributes from response.");
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
