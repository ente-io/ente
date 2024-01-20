import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:ente_auth/ui/common/web_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PlatformUtil {
  static bool isDesktop() {
    return !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  }

  static bool isMobile() {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  static bool isWeb() {
    return kIsWeb;
  }

  static TextSelectionControls get selectionControls => Platform.isAndroid
      ? materialTextSelectionControls
      : Platform.isIOS
          ? cupertinoTextSelectionControls
          : desktopTextSelectionControls;

  static openWebView(BuildContext context, String title, String url) async {
    if (PlatformUtil.isDesktop()) {
      if (!await WebviewWindow.isWebviewAvailable()) {
        launchUrlString(url);
        return;
      }

      final webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
          title: title,
        ),
      );
      webview.launch(url);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return WebPage(
            title,
            url,
          );
        },
      ),
    );
  }
}
