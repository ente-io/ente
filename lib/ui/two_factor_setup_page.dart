import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:pinput/pin_put/pin_put.dart';

class TwoFactorSetupPage extends StatefulWidget {
  final String secretCode;
  final String qrCode;

  TwoFactorSetupPage(this.secretCode, this.qrCode, {Key key}) : super(key: key);

  @override
  _TwoFactorSetupPageState createState() => _TwoFactorSetupPageState();
}

class _TwoFactorSetupPageState extends State<TwoFactorSetupPage>
    with SingleTickerProviderStateMixin {
  TabController _tabController;
  final _pinController = TextEditingController();
  final _pinPutDecoration = BoxDecoration(
    border: Border.all(color: Color.fromRGBO(45, 194, 98, 1.0)),
    borderRadius: BorderRadius.circular(15.0),
  );
  String _code = "";

  @override
  void initState() {
    _tabController = new TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "two-factor setup",
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
            Container(
              height: 360,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Theme.of(context).buttonColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(
                        text: "enter code",
                      ),
                      Tab(
                        text: "scan code",
                      )
                    ],
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _getSecretCode(),
                        _getBarCode(),
                      ],
                      controller: _tabController,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).accentColor,
            ),
            _getVerificationWidget(),
          ],
        ),
      ),
    );
  }

  Widget _getSecretCode() {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(new ClipboardData(text: widget.secretCode));
        showToast("code copied to clipboard");
      },
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(padding: EdgeInsets.all(12)),
            Text(
              "copy-paste this code\nto your authenticator app",
              style: TextStyle(
                height: 1.4,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            Padding(padding: EdgeInsets.all(16)),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    widget.secretCode,
                    style: TextStyle(
                      fontSize: 16,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(padding: EdgeInsets.all(6)),
            Text(
              "tap to copy",
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            )
          ],
        ),
      ),
    );
  }

  Widget _getBarCode() {
    return Container(
      child: Center(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(12)),
            Text(
              "scan this barcode with\nyour authenticator app",
              style: TextStyle(
                height: 1.4,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            Padding(padding: EdgeInsets.all(12)),
            Image.memory(
              Sodium.base642bin(widget.qrCode),
              height: 180,
              width: 180,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getVerificationWidget() {
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(12)),
        Text(
          "enter the 6-digit code from\nyour authenticator app",
          style: TextStyle(
            height: 1.4,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        Padding(padding: EdgeInsets.all(16)),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
          child: PinPut(
            fieldsCount: 6,
            onSubmit: (String code) {
              _verifyTwoFactorCode(code);
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
                color: Color.fromRGBO(45, 194, 98, 0.5),
              ),
            ),
            inputDecoration: InputDecoration(
              focusedBorder: InputBorder.none,
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
        Padding(padding: EdgeInsets.all(24)),
        Container(
          width: 180,
          height: 50,
          child: button(
            "confirm",
            fontSize: 18,
            padding: EdgeInsets.all(0),
            onPressed: _code.length == 6
                ? () async {
                    _verifyTwoFactorCode(_code);
                  }
                : null,
          ),
        ),
        Padding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Future<void> _verifyTwoFactorCode(String code) async {
    UserService.instance.enableTwoFactor(context, widget.secretCode, code);
  }
}
