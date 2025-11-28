import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/models/collection/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

class QrCodeDialogWidget extends StatefulWidget {
  final Collection collection;

  const QrCodeDialogWidget({
    super.key,
    required this.collection,
  });

  @override
  State<QrCodeDialogWidget> createState() => _QrCodeDialogWidgetState();
}

class _QrCodeDialogWidgetState extends State<QrCodeDialogWidget> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _shareQrCode() async {
    try {
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        final directory = await getTemporaryDirectory();
        final file = File(
          '${directory.path}/ente_qr_${widget.collection.displayName}.png',
        );
        await file.writeAsBytes(pngBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text:
                'Scan this QR code to view my ${widget.collection.displayName} album on ente',
          ),
        );

        // Close the dialog after sharing is initiated
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double qrSize = min(screenWidth - 80, 300.0);
    final enteTextTheme = getEnteTextTheme(context);
    final enteColorScheme = getEnteColorScheme(context);

    // Get the public URL for the collection
    final String publicUrl =
        CollectionsService.instance.getPublicUrl(widget.collection);

    // Get album name, truncate if too long
    final String albumName = widget.collection.displayName.length > 30
        ? '${widget.collection.displayName.substring(0, 27)}...'
        : widget.collection.displayName;

    // QR text color - always black for scanability
    const qrTextColor = textBaseLight;

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: enteColorScheme.backgroundBase,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.qrCode,
                    style: enteTextTheme.largeBold.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? enteColorScheme.backgroundElevated2
                            : qrBoxColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.close,
                        color: isDarkMode
                            ? enteColorScheme.textBase
                            : qrTextColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // QR Code with RepaintBoundary for sharing
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                decoration: BoxDecoration(
                  color: qrBoxColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Album name at top center (inside border)
                        Text(
                          albumName,
                          style: enteTextTheme.largeBold.copyWith(
                            color: qrTextColor,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // QR Code with pretty styling
                        SizedBox(
                          width: qrSize - 100,
                          height: qrSize - 100,
                          child: PrettyQrView(
                            qrImage: QrImage(
                              QrCode.fromData(
                                data: publicUrl,
                                errorCorrectLevel: QrErrorCorrectLevel.M,
                              ),
                            ),
                            decoration: PrettyQrDecoration(
                              shape: PrettyQrShape.custom(
                                const PrettyQrDotsSymbol(
                                  color: qrTextColor,
                                  unifiedFinderPattern: false,
                                  unifiedAlignmentPatterns: false,
                                ),
                                finderPattern: PrettyQrSquaresSymbol(
                                  color: qrTextColor,
                                  rounding: 0.5,
                                  unifiedFinderPattern: true,
                                  finderPatternOuterThickness: 1.4,
                                  finderPatternOuterColor:
                                      enteColorScheme.primary500,
                                  finderPatternInnerDotSize: 0.8,
                                  finderPatternInnerRounding: 1.0,
                                ),
                                alignmentPatterns: const PrettyQrSquaresSymbol(
                                  color: qrTextColor,
                                  rounding: 1.0,
                                ),
                              ),
                              image: const PrettyQrDecorationImage(
                                image: AssetImage('assets/qr_logo.png'),
                                scale: 0.25,
                                padding: EdgeInsets.all(24),
                                position:
                                    PrettyQrDecorationImagePosition.embedded,
                              ),
                              background: Colors.transparent,
                              quietZone: PrettyQrQuietZone.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 42),
                      ],
                    ),

                    // Ente branding at bottom right (inside border)
                    Positioned(
                      bottom: 0,
                      right: 2,
                      child: Text(
                        'ente',
                        style: enteTextTheme.brandSmall.copyWith(
                          color: enteColorScheme.primary500,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            GestureDetector(
              onTap: _shareQrCode,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: enteColorScheme.primary500,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.l10n.save,
                  textAlign: TextAlign.center,
                  style: enteTextTheme.bodyBold.copyWith(
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
