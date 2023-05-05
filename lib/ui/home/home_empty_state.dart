import 'package:ente_auth/l10n/l10n.dart';
import 'package:flutter/material.dart';

class HomeEmptyStateWidget extends StatelessWidget {
  final VoidCallback? onScanTap;
  final VoidCallback? onManuallySetupTap;

  const HomeEmptyStateWidget({
    Key? key,
    required this.onScanTap,
    required this.onManuallySetupTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(height: 800, width: 450),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Image.asset(
                    "assets/wallet-front-gradient.png",
                    width: 200,
                    height: 200,
                  ),
                  Text(
                    l10n.setupFirstAccount,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  const SizedBox(height: 64),
                  SizedBox(
                    width: 400,
                    child: OutlinedButton(
                      onPressed: onScanTap,
                      child: Text(l10n.importScanQrCode),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 400,
                    child: OutlinedButton(
                      onPressed: onManuallySetupTap,
                      child: Text(l10n.importEnterSetupKey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
