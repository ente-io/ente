import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/ui/settings/data/import/google_auth_image_import.dart';
import 'package:ente_auth/ui/settings/data/import/qr_scanner_overlay.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class QrScanner extends StatefulWidget {
  const QrScanner({super.key});

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  bool isNavigationPerformed = false;
  bool isScannedByImage = false;

  //Scanner Initialization
  MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          alignment: Alignment.topLeft,
          children: [
            Stack(
              children: [
                MobileScanner(
                  controller: scannerController,
                  onDetect: (capture) async {
                    if (!isNavigationPerformed) {
                      isNavigationPerformed = true;
                      if (capture.barcodes[0].rawValue!
                          .startsWith(kGoogleAuthExportPrefix)) {
                        if (isScannedByImage) {
                          final result = await showDialogWidget(
                            context: context,
                            title: l10n.importFromApp(
                              "Reminder",
                            ),
                            body:
                                'Please delete the screenshot before resuming any photo cloud sync',
                            buttons: [
                              const ButtonWidget(
                                buttonType: ButtonType.primary,
                                labelText: 'OK',
                                isInAlert: true,
                                buttonSize: ButtonSize.large,
                                buttonAction: ButtonAction.first,
                              ),
                            ],
                          );
                          if (result?.action != null &&
                              result!.action == ButtonAction.first) {
                            isScannedByImage = false;
                          }
                        }
                        HapticFeedback.vibrate();
                        List<Code> codes =
                            parseGoogleAuth(capture.barcodes[0].rawValue!);
                        scannerController.dispose();
                        Navigator.of(context).pop(codes);
                      } else {
                        showToast(context, "Invalid QR code");
                        isNavigationPerformed = false;
                      }
                    }
                  },
                ),
                // Qr code scanner overlay
                const QRScannerOverlay(),

                // Torch and gallery buttons
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Torch button
                      IconButton(
                        icon: ValueListenableBuilder(
                          valueListenable: scannerController.torchState,
                          builder: (context, state, child) {
                            switch (state) {
                              case TorchState.on:
                                return SvgPicture.asset(
                                  'assets/scanner-icons/icons/flash_on.svg',
                                );
                              case TorchState.off:
                                return SvgPicture.asset(
                                  'assets/scanner-icons/icons/flash_off.svg',
                                );
                            }
                          },
                        ),
                        iconSize: 60,
                        onPressed: () => scannerController.toggleTorch(),
                      ),

                      // Gallery button
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/scanner-icons/icons/gallery.svg',
                        ),
                        iconSize: 60,
                        onPressed: () async {
                          final result = await showDialogWidget(
                            context: context,
                            title: l10n.importFromApp(
                              "Google Authenticator (saved image)",
                            ),
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
                                labelText: l10n.cancel,
                                buttonSize: ButtonSize.large,
                                isInAlert: true,
                                buttonAction: ButtonAction.second,
                              ),
                            ],
                          );
                          if (result?.action != null &&
                              result!.action != ButtonAction.cancel) {
                            if (result.action == ButtonAction.first) {
                              List<AssetEntity>? assets =
                                  await AssetPicker.pickAssets(
                                context,
                                pickerConfig: const AssetPickerConfig(
                                  maxAssets: 1,
                                  requestType: RequestType.image,
                                ),
                              );

                              if (assets != null && assets.isNotEmpty) {
                                AssetEntity asset = assets.first;
                                File? file = await asset.file;
                                String path = file!.path;

                                if (await scannerController
                                    .analyzeImage(path)) {
                                  isScannedByImage = true;
                                  if (!mounted) return;
                                } else {
                                  if (!mounted) return;
                                  isScannedByImage = false;
                                  showToast(
                                    context,
                                    "Unable to recognize a valid code from the uploaded image",
                                  );
                                }
                              } else {
                                if (!mounted) return;
                                showToast(
                                  context,
                                  "Qr code image not selected",
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        40,
                        15,
                        40,
                        18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 5,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          const SizedBox(
                            height: 25,
                          ),
                          Text(
                            l10n.scanACode,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Close button
            Positioned(
              left: 25,
              top: 25,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: SvgPicture.asset(
                  'assets/scanner-icons/icons/cross.svg',
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcATop),
                  height: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
