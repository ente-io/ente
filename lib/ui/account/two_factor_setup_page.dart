// @dart=2.9

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/account/recovery_key_page.dart';
import 'package:photos/ui/lifecycle_event_handler.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:pinput/pin_put/pin_put.dart';

class TwoFactorSetupPage extends StatefulWidget {
  final String secretCode;
  final String qrCode;
  final Completer completer;

  const TwoFactorSetupPage(
    this.secretCode,
    this.qrCode,
    this.completer, {
    Key key,
  }) : super(key: key);

  @override
  State<TwoFactorSetupPage> createState() => _TwoFactorSetupPageState();
}

class _TwoFactorSetupPageState extends State<TwoFactorSetupPage>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  final _pinController = TextEditingController();
  final _pinPutDecoration = BoxDecoration(
    border: Border.all(color: const Color.fromRGBO(45, 194, 98, 1.0)),
    borderRadius: BorderRadius.circular(15.0),
  );
  String _code = "";
  ImageProvider _imageProvider;
  LifecycleEventHandler _lifecycleEventHandler;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _imageProvider = Image.memory(
      Sodium.base642bin(widget.qrCode),
      height: 180,
      width: 180,
    ).image;
    _lifecycleEventHandler = LifecycleEventHandler(
      resumeCallBack: () async {
        if (mounted) {
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          if (data != null && data.text != null && data.text.length == 6) {
            _pinController.text = data.text;
          }
        }
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleEventHandler);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleEventHandler);
    widget.completer.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Two-factor setup",
        ),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return SingleChildScrollView(
      reverse: true,
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 360,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.greenAlternative,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(
                        text: "Enter code",
                      ),
                      Tab(
                        text: "Scan code",
                      )
                    ],
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _getSecretCode(),
                        _getBarCode(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.secondary,
            ),
            _getVerificationWidget(),
          ],
        ),
      ),
    );
  }

  Widget _getSecretCode() {
    final Color textColor = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.secretCode));
        showToast(context, "Code copied to clipboard");
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(padding: EdgeInsets.all(12)),
          const Text(
            "Copy-paste this code\nto your authenticator app",
            style: TextStyle(
              height: 1.4,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const Padding(padding: EdgeInsets.all(16)),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: textColor.withOpacity(0.1),
              child: Center(
                child: Text(
                  widget.secretCode,
                  style: TextStyle(
                    fontSize: 15,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.all(6)),
          Text(
            "tap to copy",
            style: TextStyle(color: textColor.withOpacity(0.5)),
          )
        ],
      ),
    );
  }

  Widget _getBarCode() {
    return Center(
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(12)),
          const Text(
            "Scan this barcode with\nyour authenticator app",
            style: TextStyle(
              height: 1.4,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const Padding(padding: EdgeInsets.all(12)),
          Image(
            image: _imageProvider,
            height: 180,
            width: 180,
          ),
        ],
      ),
    );
  }

  Widget _getVerificationWidget() {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.all(12)),
        const Text(
          "Enter the 6-digit code from\nyour authenticator app",
          style: TextStyle(
            height: 1.4,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const Padding(padding: EdgeInsets.all(16)),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
          child: PinPut(
            fieldsCount: 6,
            onSubmit: (String code) {
              _enableTwoFactor(code);
            },
            onChanged: (String pin) {
              setState(() {
                _code = pin;
              });
            },
            controller: _pinController,
            submittedFieldDecoration: _pinPutDecoration.copyWith(
              borderRadius: BorderRadius.circular(20.0),
            ),
            selectedFieldDecoration: _pinPutDecoration,
            followingFieldDecoration: _pinPutDecoration.copyWith(
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(
                color: const Color.fromRGBO(45, 194, 98, 0.5),
              ),
            ),
            inputDecoration: const InputDecoration(
              focusedBorder: InputBorder.none,
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.all(24)),
        OutlinedButton(
          onPressed: _code.length == 6
              ? () async {
                  _enableTwoFactor(_code);
                }
              : null,
          child: const Text("Confirm"),
        ),
        const Padding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Future<void> _enableTwoFactor(String code) async {
    final success = await UserService.instance
        .enableTwoFactor(context, widget.secretCode, code);
    if (success) {
      _showSuccessPage();
    }
  }

  void _showSuccessPage() {
    final recoveryKey = Sodium.bin2hex(Configuration.instance.getRecoveryKey());
    routeToPage(
      context,
      RecoveryKeyPage(
        recoveryKey,
        "OK",
        showAppBar: true,
        onDone: () {},
        title: "Setup complete",
        text: "Save your recovery key if you haven't already",
        subText:
            "This can be used to recover your account if you lose your second factor",
      ),
    );
  }
}
