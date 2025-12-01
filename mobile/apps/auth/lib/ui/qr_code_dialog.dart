import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/theme/colors.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import "package:flutter/material.dart";
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

class QrCodeDialog extends StatefulWidget {
  final Code code;

  const QrCodeDialog({
    super.key,
    required this.code,
  });

  @override
  State<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<QrCodeDialog> {
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
          '${directory.path}/ente_auth_qr_${widget.code.account}.png',
        );
        await file.writeAsBytes(pngBytes);

        // Get the render box for share position (required for iPad)
        final box = context.findRenderObject() as RenderBox?;
        final sharePositionOrigin =
            box != null ? box.localToGlobal(Offset.zero) & box.size : null;

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'QR code for ${widget.code.account}',
            sharePositionOrigin: sharePositionOrigin,
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
    final double qrCodeSize =
        max(qrSize - 100, 150.0); // Ensure minimum size of 150
    final enteTextTheme = getEnteTextTheme(context);
    final enteColorScheme = getEnteColorScheme(context);
    final l10n = context.l10n;

    final String qrData = widget.code.rawData
        .replaceAll('algorithm=Algorithm.', 'algorithm=')
        .replaceAll('algorithm=sha1', 'algorithm=SHA1')
        .replaceAll('algorithm=sha256', 'algorithm=SHA256')
        .replaceAll('algorithm=sha512', 'algorithm=SHA512');

    final String accountName = widget.code.account;
    final String issuerName = widget.code.issuer;

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
                    l10n.qrCode,
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
                        color:
                            isDarkMode ? enteColorScheme.textBase : qrTextColor,
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
                        // Account name at top center (inside border)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: qrCodeSize + 40,
                          ),
                          child: Text(
                            accountName,
                            style: enteTextTheme.largeBold.copyWith(
                              color: qrTextColor,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (issuerName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: qrCodeSize,
                            ),
                            child: Text(
                              issuerName,
                              style: enteTextTheme.small.copyWith(
                                color: qrTextColor.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // QR Code with pretty styling
                        SizedBox(
                          width: qrCodeSize,
                          height: qrCodeSize,
                          child: PrettyQrView(
                            qrImage: QrImage(
                              QrCode.fromData(
                                data: qrData,
                                errorCorrectLevel: QrErrorCorrectLevel.L,
                              ),
                            ),
                            decoration: const PrettyQrDecoration(
                              shape: PrettyQrShape.custom(
                                PrettyQrDotsSymbol(
                                  color: qrTextColor,
                                  unifiedFinderPattern: false,
                                  unifiedAlignmentPatterns: false,
                                ),
                                finderPattern: PrettyQrSquaresSymbol(
                                  color: qrTextColor,
                                  rounding: 0.5,
                                  unifiedFinderPattern: true,
                                  finderPatternOuterThickness: 1.4,
                                  finderPatternOuterColor: accentColor,
                                  finderPatternInnerDotSize: 0.8,
                                  finderPatternInnerRounding: 1.0,
                                ),
                                alignmentPatterns: PrettyQrSquaresSymbol(
                                  color: qrTextColor,
                                  rounding: 1.0,
                                ),
                              ),
                              image: PrettyQrDecorationImage(
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

                    // Auth branding at bottom right (inside border)
                    Positioned(
                      bottom: 0,
                      right: 2,
                      child: SvgPicture.asset(
                        'assets/svg/auth-logo.svg',
                        height: 12,
                        colorFilter: const ColorFilter.mode(
                          accentColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Share button
            GestureDetector(
              onTap: _shareQrCode,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.share,
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
