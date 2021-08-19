import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/subscription.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

import '../loading_widget.dart';
import '../progress_dialog.dart';

const kMobilePaymentRedirect = "https://payment.ente.io/mobile";

class PaymentWebPage extends StatefulWidget {
  final String planId;
  final String actionType;

  const PaymentWebPage({Key key, this.planId, this.actionType})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _PaymentWebPage();
}

class _PaymentWebPage extends State<PaymentWebPage> {
  final _logger = Logger("PaymentWebPage");
  UserService userService = UserService.instance;
  BillingService billingService = BillingService.instance;
  ProgressDialog _dialog;
  InAppWebViewController webView;
  double progress = 0;
  String paymentWebToken;
  String basePaymentUrl = "http://192.168.1.123:3001";

  @override
  void initState() {
    userService.getPaymentToken().then((token) {
      paymentWebToken = token;
      setState(() {});
    });
    if (Platform.isAndroid && kDebugMode) {
      AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
    _dialog = createProgressDialog(context, "please wait...");
    super.initState();
  }

  Uri _getPaymentUrl(String baseEndpoint, String productId, String paymentToken,
      String actionType, String redirectUrl) {
    final queryParameters = {
      'productID': productId,
      'paymentToken': paymentToken,
      'action': actionType,
      'redirectURL': redirectUrl,
    };
    var tryParse = Uri.tryParse(baseEndpoint);
    if (kDebugMode && baseEndpoint.startsWith("http://")) {
      return Uri.http(tryParse.authority, tryParse.path, queryParameters);
    } else {
      return Uri.https(tryParse.authority, tryParse.path, queryParameters);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (paymentWebToken == null) {
      return loadWidget;
    }
    Uri paymentUri = _getPaymentUrl(basePaymentUrl, widget.planId,
        paymentWebToken, widget.actionType, kMobilePaymentRedirect);
    _logger.info("paymentUrl : $paymentUri");
    return WillPopScope(
        onWillPop: () async => _buildPageExitWidget(context),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('subscription'),
          ),
          body: Column(
            children: <Widget>[
              (progress != 1.0)
                  ? LinearProgressIndicator(value: progress)
                  : Container(),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: paymentUri),
                  onProgressChanged:
                      (InAppWebViewController controller, int progress) {
                    setState(() {
                      this.progress = progress / 100;
                    });
                  },
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                      useShouldOverrideUrlLoading: true,
                    ),
                  ),
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    var loadingUri = navigationAction.request.url;
                    _logger.info("Loading url $loadingUri");
                    // handle the payment response
                    if (_isPaymentActionComplete(loadingUri)) {
                      await handlePaymentResponse(loadingUri);
                      return NavigationActionPolicy.CANCEL;
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    _logger.info(consoleMessage);
                  },
                  onLoadStart: (controller, navigationAction) async {
                    if (!_dialog.isShowing()) {
                      await _dialog.show();
                    }
                  },
                  onLoadError: (controller, navigationAction, code, msg) async {
                    if (_dialog.isShowing()) {
                      await _dialog.hide();
                    }
                  },
                  onLoadStop: (controller, navigationAction) async {
                    if (_dialog.isShowing()) {
                      await _dialog.hide();
                    }
                  },
                ),
              ),
            ].where((Object o) => o != null).toList(),
          ),
        ));
  }

  @override
  void dispose() {
    _dialog.hide();
    super.dispose();
  }

  // show dialog to handle accidental back press.
  Future<bool> _buildPageExitWidget(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Are you sure you want to exit?'),
                actions: <Widget>[
                  TextButton(
                      child: Text('yes'),
                      onPressed: () => Navigator.of(context).pop(true)),
                  TextButton(
                      child: Text('no'),
                      onPressed: () => Navigator.of(context).pop(false)),
                ]));
  }

  bool _isPaymentActionComplete(Uri loadingUri) {
    return loadingUri.toString().startsWith(kMobilePaymentRedirect);
  }

  Future<void> handlePaymentResponse(Uri uri) async {
    var queryParams = uri.queryParameters;
    var paymentStatus = uri.queryParameters['status'] ?? '';
    _logger.fine('handle payment response with status $paymentStatus');
    if ('fail' == paymentStatus) {
      var reason = queryParams['reason'] ?? '';
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text('payment failed'),
                  content:
                      Text("unfortunately your payment failed due to $reason"),
                  actions: <Widget>[
                    TextButton(
                        child: Text('ok'),
                        onPressed: () {
                          Navigator.of(context).pop('dialog');
                          Navigator.of(context).pop(true);
                        }),
                  ]));
      return;
      // showToast("sorry, we couldn't process your payment due to $reason");
    } else if (paymentStatus == 'success') {
      await _handlePaymentSuccess(queryParams);
    } else {
      // should never reach here
      _logger.severe("unexpected payement status", uri.toString());
      Navigator.of(context).pop();
    }
  }

  // return true if verifySubscription didn't throw any exceptions
  Future<void> _handlePaymentSuccess(Map<String, String> queryParams) async {
    var checkoutSessionID = queryParams['session_id'] ?? '';
    await _dialog.show();
    try {
      var response = await billingService.verifySubscription(
          widget.planId, checkoutSessionID,
          paymentProvider: kStripe);
      await _dialog.hide();
      if (response != null) {
        var content = widget.actionType == 'buy'
            ? 'you have successfully subscribed to ente'
            : 'your ente subscription update was successful';
        await _showExitPageDialog(title: 'thank you', content: content);
      } else {
        throw Exception("verifySubscription api failed");
      }
    } catch (error) {
      _logger.severe(error);
      await _dialog.hide();
      await _showExitPageDialog(
        title: 'failed to verify payment status',
        content: 'please wait for sometime before retrying',
      );
    }
  }

  // warn the user to wait for sometime before trying another payment
  Future<dynamic> _showExitPageDialog({String title, String content}) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
                title: Text(title),
                content: Text(content),
                actions: <Widget>[
                  TextButton(
                      child: Text('ok',
                      style: TextStyle(color: Theme.of(context).buttonColor),),
                      onPressed: () {
                        Navigator.of(context).pop('dialog');
                        Navigator.of(context).pop(true);
                      }),
                ]));
  }
}
