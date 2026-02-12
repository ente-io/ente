import "dart:async";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:intl/intl.dart";
import "package:photos/generated/intl/app_localizations.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/account/email_entry_page.dart";
import "package:photos/utils/ml_util.dart";

class NameFaceBanner extends StatefulWidget {
  const NameFaceBanner({super.key});

  @override
  State<NameFaceBanner> createState() => _NameFaceBannerState();
}

class _NameFaceBannerState extends State<NameFaceBanner> {
  bool _dismissed = false;
  IndexStatus? _indexStatus;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchStatus();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (!isOfflineMode) return const SizedBox.shrink();
    if (localSettings.isOfflineNameFaceBannerDismissed) {
      return const SizedBox.shrink();
    }

    final colorScheme = getEnteColorScheme(context);
    final l10n = AppLocalizations.of(context);
    final format = NumberFormat();
    final status = _indexStatus;

    final indexed = status?.indexedItems ?? 78;
    final total =
        (status?.indexedItems ?? 78) + (status?.pendingItems ?? 25601);
    final safeTotal = total <= 0 ? 1 : total;
    final progress = (indexed / safeTotal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EmailEntryPage(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.backgroundColour,
            borderRadius: BorderRadius.circular(14.331),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.mlProgressBannerTitle,
                    style: TextStyle(
                      fontFamily: "Nunito",
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      height: 27.132 / 18,
                      letterSpacing: -0.9554,
                      color: colorScheme.greenBase,
                    ),
                  ),
                  GestureDetector(
                    onTap: _onDismiss,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: colorScheme.contentLight,
                        size: 20,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.mlProgressBannerDescription,
                style: TextStyle(
                  fontFamily: "Montserrat",
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 15.287 / 12,
                  color: colorScheme.contentLighter,
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(57),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: const Color.fromRGBO(193, 193, 193, 0.11),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.greenBase),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  l10n.mlProgressBannerStatus(
                    indexed: format.format(indexed),
                    total: format.format(safeTotal),
                  ),
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 15.287 / 10,
                    color: colorScheme.contentLighter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchStatus() async {
    try {
      final status = await getIndexStatus();
      if (!mounted) return;
      setState(() {
        _indexStatus = status;
      });
    } catch (_) {
      // Keep fallback values if indexing status is unavailable.
    }
  }

  void _onDismiss() {
    setState(() {
      _dismissed = true;
    });
    localSettings.setOfflineNameFaceBannerDismissed(true);
  }
}
