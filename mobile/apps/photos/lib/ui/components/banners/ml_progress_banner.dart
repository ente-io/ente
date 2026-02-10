import "dart:async";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:intl/intl.dart";
import "package:photos/generated/intl/app_localizations.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/ml_util.dart";

class MLProgressBanner extends StatefulWidget {
  const MLProgressBanner({super.key});

  @override
  State<MLProgressBanner> createState() => _MLProgressBannerState();
}

class _MLProgressBannerState extends State<MLProgressBanner> {
  IndexStatus? _indexStatus;
  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchStatus();
    });
  }

  Future<void> _fetchStatus() async {
    try {
      final status = await getIndexStatus();
      if (mounted) {
        setState(() {
          _indexStatus = status;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (!hasGrantedMLConsent) return const SizedBox.shrink();
    if (localSettings.isMLProgressBannerDismissed) {
      return const SizedBox.shrink();
    }

    final status = _indexStatus;
    if (status == null) return const SizedBox.shrink();
    if (status.pendingItems <= 0) return const SizedBox.shrink();

    final total = status.indexedItems + status.pendingItems;
    if (total <= 0) return const SizedBox.shrink();

    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = AppLocalizations.of(context);
    final format = NumberFormat();
    final progress = total > 0 ? status.indexedItems.toDouble() / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.backgroundColour,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.mlProgressBannerTitle,
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.greenBase,
                  ),
                ),
                GestureDetector(
                  onTap: _onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: colorScheme.textFaint,
                      size: 20,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.mlProgressBannerDescription,
              style: textTheme.miniMuted.copyWith(
                fontFamily: "Montserrat",
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.mlProgressBannerStatus(
                  indexed: format.format(status.indexedItems),
                  total: format.format(total),
                ),
                style: textTheme.tinyMuted,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2.5),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: colorScheme.fillFaint,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.greenBase,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDismiss() {
    setState(() {
      _dismissed = true;
    });
    localSettings.setMLProgressBannerDismissed(true);
  }
}
