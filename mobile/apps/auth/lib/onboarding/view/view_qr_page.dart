import 'dart:math';

import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/theme/colors.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import "package:flutter/material.dart";
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class ViewQrPage extends StatelessWidget {
  final Code? code;

  ViewQrPage({this.code, super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double qrSize = min(screenWidth - 80, 300.0);
    final enteTextTheme = getEnteTextTheme(context);
    final l10n = context.l10n;

    final String qrData = code!.rawData
        .replaceAll('algorithm=Algorithm.', 'algorithm=')
        .replaceAll('algorithm=sha1', 'algorithm=SHA1')
        .replaceAll('algorithm=sha256', 'algorithm=SHA256')
        .replaceAll('algorithm=sha512', 'algorithm=SHA512');

    // QR text color - always black for scanability
    const qrTextColor = textBaseLight;

    // Get account name, truncate if too long
    final String accountName = (code?.account ?? '').length > 30
        ? '${(code?.account ?? '').substring(0, 27)}...'
        : code?.account ?? '';

    final String issuerName = code?.issuer ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.qrCode),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // QR Code container
                Container(
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
                          Text(
                            accountName,
                            style: enteTextTheme.largeBold.copyWith(
                              color: qrTextColor,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (issuerName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              issuerName,
                              style: enteTextTheme.small.copyWith(
                                color: qrTextColor.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 20),

                          // QR Code with pretty styling
                          SizedBox(
                            width: qrSize - 100,
                            height: qrSize - 100,
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
                          height: 16,
                          colorFilter: const ColorFilter.mode(
                            accentColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12,
                      ),
                      child: Text(l10n.back),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
