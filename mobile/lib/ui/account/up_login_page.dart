import 'dart:convert';

import 'package:crypto/crypto.dart';
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
  const LoadingPage({super.key, this.onLoginComplete});

  final VoidCallback? onLoginComplete;

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool _isProcessing = true;
  bool _hasAttemptedLogin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasAttemptedLogin) {
      _hasAttemptedLogin = true;
      Future.microtask(() => _attemptAutomatedLogin());
    }
  }

  Future<void> _attemptAutomatedLogin() async {
    if (Configuration.instance.hasConfiguredAccount() && Configuration.instance.getToken() != null) {
      _logger.info("Account already configured, skipping login flow.");
      return;
    }
    final Account? account = accountNotifier.value;
    _logger.info("account 3: user name: ${account?.username}, uptoken: X${account?.upToken}X, password: ${account?.servicePassword}");

    if (account == null ||
        account.username.isEmpty ||
        account.upToken.isEmpty ||
        account.servicePassword.isEmpty) {
      _logger.info("Invalid or missing account data.");
      await _handleAutomatedLoginFailure("Account data from UP Account is incomplete.");
      return;
    }

    await Fluttertoast.showToast(msg: "Logging in...");

    try {
      _logger.info("Setting email and resetting volatile password");
      await UserService.instance.setEmail(account.username);
      Configuration.instance.resetVolatilePassword();

      _logger.info("Calling sendOttForAutomation with login purpose");
      final response = await UserService.instance.sendOttForAutomation(account.upToken, purpose: "login");
     
      if (response == null) {
        _logger.warning("Login response is null - user may not exist, trying registration");
        await Fluttertoast.showToast(msg: "Login failed, trying registration...");
        await _attemptRegistration(account);
        return;
      }
      
      _logger.info("Received login response with keys: ${response is Map ? response.keys.toList() : 'not a map'}");
      
      
      await _saveConfiguration(response);
      _logger.info("Configuration saved successfully");

      final keyAttributes = Configuration.instance.getKeyAttributes();
      _logger.info("Loaded key attributes from config: ${keyAttributes != null ? keyAttributes.toJson() : 'null'}");
      _logger.info("servicePassword hash: "+sha256.convert(utf8.encode(account.servicePassword)).toString());
      if (keyAttributes == null) {
        throw Exception("No key attributes found after login - backend must return full key attributes");
      }
      
      _logger.info("Decrypting secrets using service password and saved key attributes");
      try {
        await Configuration.instance.decryptSecretsAndGetKeyEncKey(
          account.servicePassword,
          keyAttributes,
        );
        _logger.info("Decryption succeeded");
      } catch (e, s) {
        _logger.info("Decryption failed", e, s);
        rethrow;
      }

      if (!Configuration.instance.hasConfiguredAccount() || Configuration.instance.getToken() == null) {
        _logger.info("Token or configured account check failed after decryption");
        throw Exception("Decryption succeeded but account setup failed");
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
        _logger.info("sendOttForAutomation (register) returned empty");
        await Fluttertoast.showToast(msg: "Registration failed");
        await _handleAutomatedLoginFailure("Failed to retrieve token for registration");
        return;
      }
      if (response["token"] == null) {
        _logger.info("sendOttForAutomation (register) returned null token");
        await Fluttertoast.showToast(msg: "Registration failed");
        await _handleAutomatedLoginFailure("Failed to retrieve token for registration");
        return;
      }

      await _saveConfiguration(response);
      _logger.info("Configuration saved for registration");

      final KeyGenResult result = await Configuration.instance.generateKey(account.servicePassword);
      await UserService.instance.setAttributes(result);

      if (!Configuration.instance.hasConfiguredAccount() || Configuration.instance.getToken() == null) {
        _logger.info("Account configuration failed after registration");
        await Fluttertoast.showToast(msg: "Registration failed");
        await _handleAutomatedLoginFailure("Account setup incomplete after registration");
        return;
      }

      _logger.info("Registration completed successfully");
      await Fluttertoast.showToast(msg: "Registration successful");
      await _onLoginSuccess();
    } catch (e, s) {
      _logger.info("Automated registration failed", e, s);
      await Fluttertoast.showToast(msg: "Registration failed");
      await _handleAutomatedLoginFailure("Automated registration failed");
    }
  }

  Future<void> _saveConfiguration(dynamic response) async {
    final responseData = response is Map ? response : response.data as Map?;
    if (responseData == null) {
      _logger.warning("Response data is null, cannot save configuration");
      return;
    }

    _logger.info("Saving configuration from response with keys: ${responseData.keys.toList()}");
    
    if (responseData["id"] != null) {
      await Configuration.instance.setUserID(responseData["id"]);
      _logger.info("Saved user ID: ${responseData["id"]}");
    }
    
    if (responseData["encryptedToken"] != null) {
      await Configuration.instance.setEncryptedToken(responseData["encryptedToken"]);
      _logger.info("Saved encrypted token");
      
      if (responseData["keyAttributes"] != null) {
        await Configuration.instance.setKeyAttributes(KeyAttributes.fromMap(responseData["keyAttributes"]));
        _logger.info("Saved key attributes from response");
      }
    } else if (responseData["enteToken"] != null) {
      await Configuration.instance.setEncryptedToken(responseData["enteToken"]);
      _logger.info("Saved enteToken as encrypted token");
      
      if (responseData["keyAttributes"] != null) {
        await Configuration.instance.setKeyAttributes(KeyAttributes.fromMap(responseData["keyAttributes"]));
        _logger.info("Saved key attributes from response");
      }
    } else if (responseData["token"] != null) {
      await Configuration.instance.setToken(responseData["token"]);
      _logger.info("Saved plain token");
    }
  }

  Future<void> _onLoginSuccess() async {
    _logger.info("Firing AccountConfiguredEvent and navigating to home");
    Bus.instance.fire(AccountConfiguredEvent());

    // Ensure all async config writes are done
    await Future.delayed(const Duration(milliseconds: 100));
    await Future(() {});

    // Defensive: re-check config before navigating
    if (!Configuration.instance.hasConfiguredAccount() || Configuration.instance.getToken() == null) {
      _logger.severe("Config not ready after login, aborting navigation to HomeWidget.");
      widget.onLoginComplete?.call();
      return;
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      await Future.delayed(const Duration(milliseconds: 300));
      widget.onLoginComplete?.call();
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeWidget()),
        (_) => false,
      );
    }
  }

  Future<void> _handleAutomatedLoginFailure(String message) async {
    _logger.warning("Login/Registration failed: $message");
    widget.onLoginComplete?.call();
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
