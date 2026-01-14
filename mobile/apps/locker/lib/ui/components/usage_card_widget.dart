import "package:ente_accounts/models/user_details.dart";
import "package:ente_ui/components/loading_widget.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/states/user_details_state.dart";

class UsageCardWidget extends StatelessWidget {
  const UsageCardWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final inheritedDetails = InheritedUserDetails.of(context);
    final userDetails = inheritedDetails?.userDetails;
    final isCached = inheritedDetails?.isCached ?? false;
    final isLoading = userDetails is! UserDetails || isCached;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromRGBO(21, 21, 21, 1),
              Color.fromRGBO(43, 43, 43, 1),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DotsPainter(),
                size: Size.infinite,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _UsageContent(
                userDetails: userDetails,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  static const double _dotRadius = 2.0;
  static const double _horizontalSpacing = 24.0;
  static const double _verticalSpacing = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = textBaseDark.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    final horizontalCount = (size.width / _horizontalSpacing).ceil() + 1;
    final verticalCount = (size.height / _verticalSpacing).ceil() + 1;

    for (int row = 0; row < verticalCount; row++) {
      for (int col = 0; col < horizontalCount; col++) {
        final x = col * _horizontalSpacing + (_horizontalSpacing / 2);
        final y = row * _verticalSpacing + (_verticalSpacing / 2);

        if (x <= size.width + _dotRadius && y <= size.height + _dotRadius) {
          canvas.drawCircle(Offset(x, y), _dotRadius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UsageContent extends StatelessWidget {
  final UserDetails? userDetails;
  final bool isLoading;

  const _UsageContent({
    required this.userDetails,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    final maxFileCount =
        userDetails?.getLockerFileLimit().clamp(1, double.maxFinite).toInt() ??
            100;
    final userFileCount = userDetails?.fileCount ?? 0;

    final showFamilyBreakup = _shouldShowFamilyBreakup();

    final userProgress =
        isLoading ? 0.0 : (userFileCount / maxFileCount).clamp(0.0, 1.0);
    final familyProgress = showFamilyBreakup && !isLoading
        ? (userDetails!.lockerFamilyUsage!.familyFileCount / maxFileCount)
            .clamp(0.0, 1.0)
        : 0.0;

    final formattedUsed = NumberFormat().format(userFileCount);
    final formattedMax = NumberFormat().format(maxFileCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.itemsStored,
          style: textTheme.brandSmall.copyWith(
            color: textMutedDark,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        if (isLoading)
          const SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: EnteLoadingWidget(
                size: 24,
                padding: 0,
                color: textBaseDark,
              ),
            ),
          )
        else
          RichText(
            text: TextSpan(
              style: textTheme.h2Bold.copyWith(
                color: textBaseDark,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(text: formattedUsed),
                TextSpan(
                  text: " ${context.l10n.of_} ",
                  style: textTheme.h2Bold.copyWith(
                    color: textMutedDark,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(text: formattedMax),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 8,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(193, 193, 193, 0.11),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              if (showFamilyBreakup)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth * familyProgress,
                      height: 8,
                      decoration: BoxDecoration(
                        color: textBaseDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth * userProgress,
                    height: 8,
                    decoration: BoxDecoration(
                      color: showFamilyBreakup
                          ? colorScheme.primary700
                          : colorScheme.primary700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (showFamilyBreakup && !isLoading)
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.usageYou,
                style: textTheme.miniBold.copyWith(color: textBaseDark),
              ),
              const SizedBox(width: 16),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: textBaseDark,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.usageFamily,
                style: textTheme.miniBold.copyWith(color: textBaseDark),
              ),
            ],
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }

  bool _shouldShowFamilyBreakup() {
    if (userDetails == null) return false;
    if (!userDetails!.isPartOfFamily()) return false;
    return userDetails!.lockerFamilyUsage != null;
  }
}
