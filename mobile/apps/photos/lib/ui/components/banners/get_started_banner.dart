import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/account/email_entry_page.dart";
import "package:photos/ui/components/banners/banner_action_button.dart";

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

    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = AppLocalizations.of(context);

    final titleStyle = textTheme.largeBold.copyWith(
      fontFamily: "Nunito",
      fontWeight: FontWeight.w800,
      fontSize: 20,
      height: 24 / 18,
      letterSpacing: -1,
      color: Colors.white,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: GestureDetector(
        onTap: _onGetStarted,
        child: Container(
          height: 180,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.greenBase,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 235),
                            child: Text(
                              l10n.moreThanJustAGallery,
                              style: titleStyle,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _onDismiss,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: greenDark,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                color: contentDark,
                                size: 18,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 235),
                      child: Text(
                        l10n.encryptedBackupDescription,
                        style: textTheme.smallMuted.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: BannerActionButton(
                  label: l10n.getStarted,
                  onTap: _onGetStarted,
                  variant: BannerActionButtonVariant.neutral,
                ),
              ),
              Positioned(
                right: 16,
                bottom: 12,
                child: IgnorePointer(
                  child: Image.asset(
                    "assets/ducky_get_started.png",
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
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
