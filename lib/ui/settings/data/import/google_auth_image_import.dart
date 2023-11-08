import 'dart:async';
import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

const kGoogleAuthExportPrefix = 'otpauth-migration://offline?data=';

Future<void> showGoogleAuthImageInstruction(BuildContext context) async {
  MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );
  final l10n = context.l10n;
  final result = await showDialogWidget(
    context: context,
    title: 'Google Authenticator (saved image)',
    body:
        'Please turn off all photo cloud sync from all apps, including iCloud, Google Photo, OneDrive, etc. \nAlso if you have a second smartphone, it is safer to import by scanning QR code.',
    buttons: [
      const ButtonWidget(
        buttonType: ButtonType.primary,
        labelText: 'Import from image',
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
      List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: const AssetPickerConfig(
          maxAssets: 1,
        ),
      );

      if (assets != null && assets.isNotEmpty) {
        AssetEntity asset = assets.first;
        File? file = await asset.file;
        String path = file!.path;

        if (await scannerController.analyzeImage(path)) {
          final barcode = await scannerController.barcodes.first;
          showToast(context, "$barcode");
        } else {
          showToast(context, "Failed to scan image");
        }
      } else {
        showToast(context, "Image not selected");
      }
    }
  }
}
