import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:photos/ui/loading_widget.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [_hasLoadedPage ? Container() : loadWidget],
      ),
      body: InAppWebView(
        initialUrl: widget.url,
        onLoadStop: (c, url) {
          setState(() {
            _hasLoadedPage = true;
          });
        },
      ),
    );
  }
}
