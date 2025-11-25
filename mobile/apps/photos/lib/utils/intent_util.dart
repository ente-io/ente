import "package:flutter/services.dart";
import "package:media_extension/media_extension.dart";
import "package:media_extension/media_extension_action_types.dart";

Future<MediaExtentionAction> initIntentAction() async {
  final mediaExtensionPlugin = MediaExtension();
  MediaExtentionAction mediaExtensionAction;
  try {
    mediaExtensionAction = await mediaExtensionPlugin.getIntentAction();
  } on PlatformException {
    mediaExtensionAction = MediaExtentionAction(action: IntentAction.main);
  } catch (error) {
    mediaExtensionAction = MediaExtentionAction(action: IntentAction.main);
  }
  return mediaExtensionAction;
}
