import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/settings/data/import_page.dart';
import 'package:ente_auth/utils/navigation_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class HomeEmptyStateWidget extends StatelessWidget {
  final VoidCallback? onScanTap;
  final VoidCallback? onManuallySetupTap;

  const HomeEmptyStateWidget({
    super.key,
    required this.onScanTap,
    required this.onManuallySetupTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
            minWidth: 450,
          ),
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
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 64),
                    if (PlatformUtil.isMobile())
                      SizedBox(
                        width: 400,
                        child: OutlinedButton(
                          onPressed: onScanTap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            l10n.importScanQrCode,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 400,
                      child: OutlinedButton(
                        onPressed: onManuallySetupTap,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          l10n.importEnterSetupKey,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 54),
                    InkWell(
                      onTap: () {
                        routeToPage(context, const ImportCodePage());
                      },
                      child: Text(
                        l10n.importCodes,
                        textAlign: TextAlign.center,
                        style: getEnteTextTheme(context)
                            .bodyFaint
                            .copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: () {
                        try {
                          PlatformUtil.openWebView(
                            context,
                            context.l10n.faq,
                            "https://help.ente.io/auth/faq",
                          );
                        } catch (e) {
                          Logger("HomeEmptyStateWidget")
                              .severe("Failed to open FAQ", e);
                        }
                      },
                      child: Text(
                        l10n.faq,
                        textAlign: TextAlign.center,
                        style: getEnteTextTheme(context)
                            .bodyFaint
                            .copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
