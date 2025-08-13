import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';

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
    // For desktop, always open in external browser
    // For mobile, open in external browser (apps can override this if they have web view)
    await launchUrlString(url);
  }

  static Future<void> shareFile(
    String fileName,
    String extension,
    Uint8List bytes,
    MimeType type,
  ) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await FileSaver.instance.saveAs(
          name: fileName,
          fileExtension: extension,
          bytes: bytes,
          mimeType: type,
        );
      } else {
        await FileSaver.instance.saveFile(
          name: fileName,
          fileExtension: extension,
          bytes: bytes,
          mimeType: type,
        );
      }
    } catch (_) {}
  }

  // Needed to fix issue with local_auth on Windows
  // https://github.com/flutter/flutter/issues/122322
  static Future<void> refocusWindows() async {
    if (!Platform.isWindows) return;
    await windowManager.blur();
    await windowManager.focus();
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setAlwaysOnTop(false);
  }
}
