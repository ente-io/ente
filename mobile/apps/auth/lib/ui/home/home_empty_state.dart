import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/home/widgets/rounded_action_buttons.dart';
import 'package:ente_auth/ui/settings/data/import_page.dart';
import 'package:ente_auth/utils/navigation_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    final colorScheme = getEnteColorScheme(context);
    final isDarkTheme = !colorScheme.isLightTheme;
    final bgSvgPath = isDarkTheme
        ? 'assets/svg/empty-state-bg-dark.svg'
        : 'assets/svg/empty-state-bg-light.svg';
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final extraBottomPadding = PlatformUtil.isMobile()
        ? (bottomPadding > 0 ? bottomPadding : 24.0)
        : 24.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: extraBottomPadding,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 188,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              bottom: 6,
                              child: SvgPicture.asset(
                                bgSvgPath,
                                width: 224,
                                height: 142,
                              ),
                            ),
                            Image.asset(
                              'assets/onboarding-2.png',
                              height: 188,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 221,
                        child: Text(
                          l10n.setupFirstAccount,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.textBase,
                            fontSize: 20,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (PlatformUtil.isMobile()) ...[
                          RoundedButton(
                            label: l10n.importScanQrCode,
                            onPressed: onScanTap,
                            width: double.infinity,
                          ),
                          const SizedBox(height: 12),
                          RoundedButton(
                            label: l10n.importEnterSetupKey,
                            onPressed: onManuallySetupTap,
                            width: double.infinity,
                            type: RoundedButtonType.secondary,
                          ),
                        ] else
                          RoundedButton(
                            label: l10n.importEnterSetupKey,
                            onPressed: onManuallySetupTap,
                            width: double.infinity,
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextLinkButton(
                              label: l10n.importCodes,
                              onTap: () {
                                routeToPage(context, const ImportCodePage());
                              },
                            ),
                            TextLinkButton(
                              label: l10n.faq,
                              onTap: () {
                                PlatformUtil.openWebView(
                                  context,
                                  context.l10n.faq,
                                  'https://ente.io/help/auth/faq',
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
