import 'dart:async';

import "package:ente_accounts/ente_accounts.dart";
import 'package:ente_ui/components/loading_widget.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import "package:hugeicons/hugeicons.dart";
import 'package:intl/intl.dart';
import "package:locker/l10n/l10n.dart";

class UsageCardWidget extends StatefulWidget {
  const UsageCardWidget({
    super.key,
  });

  @override
  State<UsageCardWidget> createState() => _UsageCardWidgetState();
}

class _UsageCardWidgetState extends State<UsageCardWidget> {
  static const maxFileCount = 1000;
  int? _fileCount;

  @override
  void initState() {
    super.initState();
    _loadFileCount();
  }

  Future<void> _loadFileCount() async {
    final userDetails = await UserService.instance.getUserDetailsV2(
      memoryCount: true,
      shouldCache: true,
    );
    setState(() {
      _fileCount = userDetails.fileCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final usedCount = _fileCount ?? 0;
    final progress = maxFileCount > 0 ? usedCount / maxFileCount : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8.0),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedCloudUpload,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.usage,
                      style: textTheme.bodyBold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    _fileCount != null
                        ? Text(
                            context.l10n.fileCount(
                              NumberFormat().format(usedCount),
                              NumberFormat().format(maxFileCount),
                            ),
                            style: textTheme.smallMuted.copyWith(
                              color: Colors.white,
                            ),
                          )
                        : SizedBox(
                            width: 60,
                            height: 12,
                            child: EnteLoadingWidget(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
