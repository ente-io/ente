import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/account/email_entry_page.dart";

class GetStartedBanner extends StatefulWidget {
  const GetStartedBanner({super.key});

  @override
  State<GetStartedBanner> createState() => _GetStartedBannerState();
}

class _GetStartedBannerState extends State<GetStartedBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (localSettings.isOfflineGetStartedBannerDismissed) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final colorScheme = getEnteColorScheme(context);

    const titleStyle = TextStyle(
      fontFamily: "Nunito",
      fontWeight: FontWeight.w900,
      fontSize: 22,
      height: 22 / 22,
      color: Colors.white,
    );
    // Subtitle uses Inter (the Ente design system default) to match the
    // pre-redesign banner. Inter has all weight files declared in
    // pubspec.yaml, so SemiBold (w600) resolves correctly — Montserrat
    // only ships the Bold file and would render at the wrong weight.
    final descriptionStyle = TextStyle(
      fontFamily: "Inter",
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 20 / 12,
      letterSpacing: -0.2,
      color: Colors.white.withValues(alpha: 0.8),
    );
    const buttonStyle = TextStyle(
      fontFamily: "Nunito",
      fontWeight: FontWeight.w900,
      fontSize: 14,
      height: 14 / 14,
      letterSpacing: -0.48,
      color: Colors.black,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GestureDetector(
        onTap: _onGetStarted,
        child: Container(
          width: double.infinity,
          height: 188,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: colorScheme.greenBase,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final innerWidth = constraints.maxWidth - 32;
              final titleMaxWidth =
                  (innerWidth - 32).clamp(120.0, double.infinity);
              // 12px Inter SemiBold needs ~240px to fit the English
              // description on two lines; clamp so it doesn't overflow
              // on very narrow devices.
              final descMaxWidth = innerWidth < 240.0 ? innerWidth : 240.0;

              return Stack(
                children: [
                  Positioned(
                    right: 8,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Image.asset(
                        "assets/ducky_10gb_free.png",
                        width: 188,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: titleMaxWidth,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n.offlineHomeSignupBannerTitle,
                                maxLines: 1,
                                softWrap: false,
                                style: titleStyle,
                              ),
                            ),
                          ),
                          const SizedBox(height: 13),
                          SizedBox(
                            width: descMaxWidth,
                            child: Text(
                              l10n.offlineHomeSignupBannerDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: descriptionStyle,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _onGetStarted,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.offlineHomeSignupBannerAction,
                                style: buttonStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: _onDismiss,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onDismiss() async {
    setState(() {
      _dismissed = true;
    });
    await localSettings.setOfflineGetStartedBannerDismissed(true);
  }

  Future<void> _onGetStarted() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EmailEntryPage(
          showReferralSourceField: false,
          referralSource: "Offline",
        ),
      ),
    );
  }
}
