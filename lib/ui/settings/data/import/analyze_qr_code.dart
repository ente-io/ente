import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
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
                  onDetect: (capture) {
                    if (!isNavigationPerformed) {
                      isNavigationPerformed = true;
                      HapticFeedback.vibrate();
                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            buttonPadding: const EdgeInsets.all(0),
                            actionsAlignment: MainAxisAlignment.center,
                            alignment: Alignment.center,
                            insetPadding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: const Text(
                              'Scan result',
                              style: TextStyle(
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            content: Text(
                              ' ${capture.barcodes[0].rawValue!}',
                              style: const TextStyle(
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            actions: [
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      isNavigationPerformed = false;
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          'OK',
                                          style: TextStyle(
                                            letterSpacing: 0.5,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
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
                            title: l10n.importFromApp("Google Authenticator (saved image)"),
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
                                ),
                              );

                              if (assets != null && assets.isNotEmpty) {
                                AssetEntity asset = assets.first;
                                File? file = await asset.file;
                                String path = file!.path;

                                if (await scannerController
                                    .analyzeImage(path)) {
                                  if (!mounted) return;
                                } else {
                                  if (!mounted) return;
                                  showToast(context, "Failed to scan image");
                                }
                              } else {
                                if (!mounted) return;
                                showToast(context, "Image not selected");
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
                          const Text(
                            'Scan QR code',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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
