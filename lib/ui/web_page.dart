import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebPage extends StatefulWidget {
  final String title;
  final String url;

  const WebPage(this.title, this.url, {Key key}) : super(key: key);

  @override
  _WebPageState createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  bool _hasLoadedPage = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [_hasLoadedPage ? Container() : loadWidget],
      ),
      body: WebView(
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        onPageFinished: (url) {
          setState(() {
            _hasLoadedPage = true;
          });
        },
      ),
    );
  }
}
