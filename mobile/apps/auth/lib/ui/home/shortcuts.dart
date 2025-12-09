import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:flutter/widgets.dart';
import 'package:move_to_background/move_to_background.dart';

class CopyIntent extends Intent {
  const CopyIntent();
}

class CopyNextIntent extends Intent {
  const CopyNextIntent();
}

class CopyAction extends Action<CopyIntent> {
  final BuildContext context;
  final Code code;

  CopyAction(this.context, this.code);

  @override
  Object? invoke(CopyIntent intent) {
    _copyToClipboard(
      getOTP(code),
      context: context,
      confirmationMessage: AppLocalizations.of(context).copiedToClipboard,
    );
    _updateCodeMetadata(code);
    return null;
  }
}

class CopyNextAction extends Action<CopyNextIntent> {
  final BuildContext context;
  final Code code;

  CopyNextAction(this.context, this.code);

  @override
  Object? invoke(CopyNextIntent intent) {
    if (!code.type.isTOTPCompatible) {
      showToast(context, context.l10n.notSupportedForHOTP);
      return null;
    }
    _copyToClipboard(
      getNextTotp(code),
      context: context,
      confirmationMessage: context.l10n.copiedNextToClipboard,
    );
    _updateCodeMetadata(code);
    return null;
  }
}

void _copyToClipboard(
  String content, {
  required BuildContext context,
  required String confirmationMessage,
}) async {
  final shouldMinimizeOnCopy =
      PreferenceService.instance.shouldMinimizeOnCopy();

  await FlutterClipboard.copy(content);
  showToast(context, confirmationMessage);
  if (Platform.isAndroid && shouldMinimizeOnCopy) {
    // ignore: unawaited_futures
    MoveToBackground.moveTaskToBack();
  }
}

Future<void> _updateCodeMetadata(Code code) async {
  final sortKey = PreferenceService.instance.codeSortKey();
  // ignore: unnecessary_null_comparison
  if (sortKey == null) return;
  Future.delayed(const Duration(milliseconds: 100), () {
    if (sortKey == CodeSortKey.mostFrequentlyUsed ||
        sortKey == CodeSortKey.recentlyUsed) {
      final display = code.display;
      final Code updatedCode = code.copyWith(
        display: display.copyWith(
          tapCount: display.tapCount + 1,
          lastUsedAt: DateTime.now().microsecondsSinceEpoch,
        ),
      );
      CodeStore.instance.addCode(updatedCode);
    }
  });
}

