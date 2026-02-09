import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/typedefs.dart";

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
      fontFamily: "Montserrat",
      fontWeight: FontWeight.bold,
      fontSize: 16,
      letterSpacing: -1,
      color: Colors.white,
    );

    const descriptionStyle = TextStyle(
      fontFamily: "Montserrat",
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 1.3,
      color: Color.fromRGBO(255, 255, 255, 0.79),
    );

    const buttonTextStyle = TextStyle(
      fontFamily: "Montserrat",
      fontWeight: FontWeight.w600,
      fontSize: 10,
      color: Colors.black,
    );

    return Container(
      height: 156,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: GradientRotation(0.19),
          colors: [
            Color.fromRGBO(4, 122, 23, 1),
            Color.fromRGBO(8, 194, 37, 1),
            Color.fromRGBO(72, 240, 98, 1),
          ],
          stops: [0.0264, 0.5255, 1.0],
        ),
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
            bottom: 0,
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
