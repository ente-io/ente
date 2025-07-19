import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

Rect _sharePosOrigin(BuildContext? context, GlobalKey? key) {
  late final Rect rect;
  if (context != null) {
    rect = shareButtonRect(context, key);
  } else {
    rect = const Offset(20.0, 20.0) & const Size(10, 10);
  }
  return rect;
}

/// Returns the rect of button if context and key are not null
/// If key is null, returned rect will be at the center of the screen
Rect shareButtonRect(BuildContext context, GlobalKey? shareButtonKey) {
  Size size = MediaQuery.sizeOf(context);
  final RenderObject? renderObject =
      shareButtonKey?.currentContext?.findRenderObject();
  RenderBox? renderBox;
  if (renderObject != null && renderObject is RenderBox) {
    renderBox = renderObject;
  }
  if (renderBox == null) {
    return Rect.fromLTWH(0, 0, size.width, size.height / 2);
  }
  size = renderBox.size;
  final Offset position = renderBox.localToGlobal(Offset.zero);
  return Rect.fromCenter(
    center: position + Offset(size.width / 2, size.height / 2),
    width: size.width,
    height: size.height,
  );
}

Future<ShareResult> shareText(
  String text, {
  BuildContext? context,
  GlobalKey? key,
}) async {
  try {
    final sharePosOrigin = _sharePosOrigin(context, key);
    return Share.share(
      text,
      sharePositionOrigin: sharePosOrigin,
    );
  } catch (e, s) {
    Logger("ShareUtil").severe("failed to share text", e, s);
    return ShareResult.unavailable;
  }
}

Future<ShareResult> shareFiles(
  List<XFile> files, {
  BuildContext? context,
  GlobalKey? key,
  String? text,
}) async {
  try {
    final sharePosOrigin = _sharePosOrigin(context, key);
    return Share.shareXFiles(
      files,
      text: text,
      sharePositionOrigin: sharePosOrigin,
    );
  } catch (e, s) {
    Logger("ShareUtil").severe("failed to share files", e, s);
    return ShareResult.unavailable;
  }
}
