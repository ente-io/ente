import 'dart:async';
import 'dart:convert';

import 'package:base32/base32.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/models/protos/googleauth.pb.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/ui/scanner_gauth_page.dart';
import 'package:ente_auth/ui/settings/data/import/import_success.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

const kGoogleAuthExportPrefix = 'otpauth-migration://offline?data=';

Future<void> showGoogleAuthInstruction(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialogWidget(
    context: context,
    title: l10n.importFromApp("Google Authenticator"),
    body: l10n.importGoogleAuthGuide,
    buttons: [
      if (PlatformUtil.isMobile())
        ButtonWidget(
          buttonType: ButtonType.primary,
          labelText: l10n.scanAQrCode,
          isInAlert: true,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.first,
        ),
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: context.l10n.cancel,
        buttonSize: ButtonSize.large,
        isInAlert: true,
        buttonAction: ButtonAction.second,
      ),
    ],
  );
  if (result?.action != null && result!.action != ButtonAction.cancel) {
    if (result.action == ButtonAction.first) {
      final List<Code>? codes = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return const ScannerGoogleAuthPage();
          },
        ),
      );
      if (codes == null || codes.isEmpty) {
        return;
      }
      for (final code in codes) {
        await CodeStore.instance.addCode(code, shouldSync: false);
      }
      unawaited(AuthenticatorService.instance.onlineSync());
      // ignore: unawaited_futures
      importSuccessDialog(context, codes.length);
    }
  }
}

List<Code> parseGoogleAuth(String qrCodeData) {
  try {
    List<Code> codes = <Code>[];
    final String payload = qrCodeData.substring(kGoogleAuthExportPrefix.length);
    final Uint8List base64Decoded = base64Decode(Uri.decodeComponent(payload));
    final MigrationPayload mPayload =
        MigrationPayload.fromBuffer(base64Decoded);
    for (var otpParameter in mPayload.otpParameters) {
      // Build the OTP URL
      String otpUrl;
      String issuer = otpParameter.issuer;
      String account = otpParameter.name;
      var counter = otpParameter.counter;
      // Create a list of bytes from the list of integers.
      Uint8List bytes = Uint8List.fromList(otpParameter.secret);

      // Encode the bytes to base 32.
      String base32String = base32.encode(bytes);
      String secret = base32String;
      // identify digit count
      int digits = 6;
      int timer = 30; // default timer, no field in Google Auth
      Algorithm algorithm = Algorithm.sha1;
      switch (otpParameter.algorithm) {
        case MigrationPayload_Algorithm.ALGORITHM_MD5:
          throw Exception('GoogleAuthImport: MD5 is not supported');
        case MigrationPayload_Algorithm.ALGORITHM_SHA1:
          algorithm = Algorithm.sha1;
          break;
        case MigrationPayload_Algorithm.ALGORITHM_SHA256:
          algorithm = Algorithm.sha256;
          break;
        case MigrationPayload_Algorithm.ALGORITHM_SHA512:
          algorithm = Algorithm.sha512;
          break;
        case MigrationPayload_Algorithm.ALGORITHM_UNSPECIFIED:
          algorithm = Algorithm.sha1;
          break;
      }
      switch (otpParameter.digits) {
        case MigrationPayload_DigitCount.DIGIT_COUNT_EIGHT:
          digits = 8;
          break;
        case MigrationPayload_DigitCount.DIGIT_COUNT_SIX:
          digits = 6;
          break;
        case MigrationPayload_DigitCount.DIGIT_COUNT_UNSPECIFIED:
          digits = 6;
      }

      if (otpParameter.type == MigrationPayload_OtpType.OTP_TYPE_TOTP ||
          otpParameter.type == MigrationPayload_OtpType.OTP_TYPE_UNSPECIFIED) {
        otpUrl =
            'otpauth://totp/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=${algorithm.name}&digits=$digits&period=$timer';
      } else if (otpParameter.type == MigrationPayload_OtpType.OTP_TYPE_HOTP) {
        otpUrl =
            'otpauth://hotp/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=${algorithm.name}&digits=$digits&counter=$counter';
      } else {
        throw Exception('Invalid OTP type');
      }
      codes.add(Code.fromOTPAuthUrl(otpUrl));
    }
    return codes;
  } catch (e, s) {
    Logger("GoogleAuthImport")
        .severe("Error while parsing Google Auth QR code", e, s);
    throw Exception('Failed to parse Google Auth QR code \n ${e.toString()}');
  }
}
