import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
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

    const titleStyle = TextStyle(
      fontFamily: "Nunito",
      fontWeight: FontWeight.w800,
      fontSize: 18,
      height: 28 / 18,
      letterSpacing: -1,
      color: Colors.white,
    );

    const descriptionStyle = TextStyle(
      fontFamily: "Montserrat",
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 18 / 12,
      color: Color.fromRGBO(255, 255, 255, 0.8),
    );

    const buttonTextStyle = TextStyle(
      fontFamily: "Montserrat",
      fontWeight: FontWeight.w600,
      fontSize: 10,
      height: 12 / 10,
      color: Colors.black,
    );

    return GestureDetector(
      onTap: _onGetStarted,
      child: Container(
        height: 165,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: getEnteColorScheme(context).greenBase,
        ),
        child: Stack(
          clipBehavior: Clip.none,
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
                        child: Text(
                          AppLocalizations.of(context).moreThanJustAGallery,
                          style: titleStyle,
                        ),
                      ),
                      GestureDetector(
                        onTap: _onDismiss,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(
                          height: 20,
                          width: 20,
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              color: Colors.white,
                              size: 20,
                              strokeWidth: 2,
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
                      AppLocalizations.of(context).encryptedBackupDescription,
                      style: descriptionStyle,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _onGetStarted,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          AppLocalizations.of(context).getStarted,
                          style: buttonTextStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: IgnorePointer(
                child: Image.asset(
                  "assets/ducky_get_started.png",
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
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
        builder: (_) => const EmailEntryPage(),
      ),
    );
  }
}
