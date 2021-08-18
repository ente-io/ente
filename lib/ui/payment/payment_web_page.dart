import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:logging/logging.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

import '../progress_dialog.dart';

const kMobilePaymentRedirect = "ente://payment/";

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
      return Container();
    }
    Uri paymentUri = _getPaymentUrl(basePaymentUrl, widget.planId,
        paymentWebToken, widget.actionType, kMobilePaymentRedirect);
    _logger.info("paymentUrl : $paymentUri");
    return WillPopScope(
        onWillPop: () async => showDialog(
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
                    ])),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ente payment'),
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
                    if (isPaymentActionComplete(loadingUri)) {
                      // handle the payment response
                      await handlePaymentResponse(loadingUri);
                      // and cancel the request
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
    super.dispose();
  }

  bool isPaymentActionComplete(Uri loadingUri) {
    return loadingUri.toString().startsWith(kMobilePaymentRedirect);
  }

  Future<void> handlePaymentResponse(Uri uri) async {
    var queryParams = uri.queryParameters;
    _logger.info(queryParams);
    // success or fail
    var paymentStatus = queryParams['status'] ?? '';
    var reason = queryParams['reason'] ?? '';
    if ('fail' == paymentStatus) {
      showToast("sorry, we couldn't process your payment due to $reason");
    } else if (paymentStatus == 'success') {
      // sessionID can be null in case of update.
      var checkoutSessionID = queryParams['session_id'] ?? '';
      await _dialog.show();
      _logger.info("Receiving checkoutSession ID: $checkoutSessionID");
      await billingService
          .verifySubscription(widget.planId, checkoutSessionID,
              paymentProvider: "stripe")
          .then((value) {
        showToast("thank you for subscribing to ente!");
      });
      if (_dialog.isShowing()) {
        await _dialog.hide();
      }
      Navigator.of(context).pop(true);
    }
  }
}
