import 'package:ente_ui/components/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebPage extends StatefulWidget {
  final String title;
  final String url;

  const WebPage(this.title, this.url, {super.key});

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  bool _hasLoadedPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // force dark theme for appBar till website/family plans add supports for light theme
        backgroundColor: const Color.fromRGBO(10, 20, 20, 1.0),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title),
        actions: [_hasLoadedPage ? Container() : const EnteLoadingWidget()],
      ),
      backgroundColor: Colors.black,
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
        ),
        onLoadStop: (c, url) {
          setState(() {
            _hasLoadedPage = true;
          });
        },
      ),
    );
  }
}
