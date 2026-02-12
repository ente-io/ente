import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/theme/ente_theme.dart";

class GetStartedBanner extends StatelessWidget {
  final FutureVoidCallback onGetStarted;
  final VoidCallback? onDismiss;

  const GetStartedBanner({
    super.key,
    required this.onGetStarted,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
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

    return Container(
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
                    if (onDismiss != null)
                      GestureDetector(
                        onTap: onDismiss,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            color: Colors.white,
                            size: 20,
                            strokeWidth: 2,
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
                  onTap: onGetStarted,
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
    );
  }
}
