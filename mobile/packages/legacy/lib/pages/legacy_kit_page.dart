import "dart:typed_data";

import "package:collection/collection.dart";
import "package:ente_legacy/components/gradient_button.dart";
import "package:ente_legacy/components/legacy_kit_icons.dart";
import "package:ente_legacy/models/legacy_kit_models.dart";
import "package:ente_legacy/pages/create_legacy_kit_sheet.dart";
import "package:ente_legacy/services/legacy_kit_pdf_service.dart";
import "package:ente_legacy/services/legacy_kit_service.dart";
import "package:ente_rust/ente_rust.dart" as rust;
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/alert_bottom_sheet.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/file_saver_util.dart";
import "package:file_saver/file_saver.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";

typedef LegacyKitAuthenticator = Future<bool> Function(
  BuildContext context,
  String reason,
);

class LegacyKitPage extends StatefulWidget {
  final LegacyKit kit;
  final String accountEmail;
  final LegacyKitAuthenticator? authenticator;
  final VoidCallback? onChanged;

  const LegacyKitPage({
    required this.kit,
    required this.accountEmail,
    this.authenticator,
    this.onChanged,
    super.key,
  });

  @override
  State<LegacyKitPage> createState() => _LegacyKitPageState();
}

class _LegacyKitPageState extends State<LegacyKitPage> {
  late LegacyKit _kit = widget.kit;
  bool _loadingRecoveryDetails = false;
  bool _updatingNotice = false;
  LegacyKitOwnerRecoverySessionDetails? _recoveryDetails;

  @override
  void initState() {
    super.initState();
    if (_kit.hasActiveRecoverySession) {
      _loadRecoveryDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final canUpdateNotice = !_kit.hasActiveRecoverySession && !_updatingNotice;

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_outlined),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text(
                  context.strings.legacyKit,
                  style: textTheme.largeBold.copyWith(
                    fontSize: 20.0,
                    height: 28 / 20,
                  ),
                ),
                if (_kit.hasActiveRecoverySession) ...[
                  const SizedBox(height: 20),
                  _RecoveryBanner(
                    session: _kit.activeRecoverySession!,
                    parts: _kit.parts,
                    loadingDetails: _loadingRecoveryDetails,
                    details: _recoveryDetails,
                    onBlockRecovery: _blockRecovery,
                  ),
                ],
                const SizedBox(height: 20),
                ..._buildPartRows(colorScheme),
                const SizedBox(height: 20),
                Text(
                  context.strings.settings,
                  style: textTheme.bodyBold,
                ),
                const SizedBox(height: 8),
                _RecoveryWaitTimeRow(
                  title: context.strings.recoveryWaitTime,
                  value: _formatNoticePeriod(_kit.noticePeriodInHours),
                  canEdit: canUpdateNotice,
                  onTap: _editRecoveryWaitTime,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientButton(
                  text: context.strings.downloadAll,
                  height: 52,
                  textStyle: textTheme.small.copyWith(height: 20 / 14),
                  onTap: _downloadAll,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _deleteKit,
                  child: SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        context.strings.deleteLegacyKit,
                        style: textTheme.small.copyWith(
                          color: colorScheme.warning700,
                          height: 20 / 14,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.warning700,
                        ),
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

  List<Widget> _buildPartRows(colorScheme) {
    final cardColor = colorScheme.isLightTheme
        ? Colors.white
        : colorScheme.backgroundElevated2;
    return [
      for (var index = 0; index < _kit.parts.length; index++) ...[
        _LegacyKitPartRow(
          name: _kit.parts[index].name,
          subtitle: context.strings.legacyKitPartOf(
            _kit.parts[index].index,
            _kit.parts.length,
          ),
          cardColor: cardColor,
          avatarColor: _avatarColor(index),
          onTap: () async {
            await _downloadPart(_kit.parts[index]);
          },
        ),
        if (index < _kit.parts.length - 1) const SizedBox(height: 8),
      ],
    ];
  }

  Color _avatarColor(int index) {
    const colors = [
      Color(0xFF8A38F5),
      Color(0xFFFFA939),
      Color(0xFF1071FF),
    ];
    return colors[index % colors.length];
  }

  Future<void> _loadRecoveryDetails() async {
    setState(() {
      _loadingRecoveryDetails = true;
    });
    try {
      final details =
          await LegacyKitService.instance.getRecoverySession(_kit.id);
      if (mounted) {
        setState(() {
          _recoveryDetails = details;
        });
      }
    } catch (_) {
      if (mounted) {
        showShortToast(context, context.strings.somethingWentWrong);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingRecoveryDetails = false;
        });
      }
    }
  }

  Future<void> _editRecoveryWaitTime() async {
    final selectedDays = await showLegacyKitRecoveryWaitTimeSheet(
      context,
      selectedDays: _kit.noticePeriodInHours ~/ 24,
    );
    if (selectedDays == null || selectedDays * 24 == _kit.noticePeriodInHours) {
      return;
    }
    if (!await _authenticate(context.strings.authToManageLegacyKit)) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _updatingNotice = true;
    });
    final dialog = createProgressDialog(context, context.strings.pleaseWait);
    await dialog.show();

    Object? updateError;
    try {
      await LegacyKitService.instance.updateRecoveryNotice(
        kitId: _kit.id,
        noticePeriodInHours: selectedDays * 24,
      );
      if (mounted) {
        setState(() {
          _kit = LegacyKit(
            id: _kit.id,
            noticePeriodInHours: selectedDays * 24,
            parts: _kit.parts,
            createdAt: _kit.createdAt,
            updatedAt: _kit.updatedAt,
            activeRecoverySession: _kit.activeRecoverySession,
          );
        });
      }
      try {
        await _refreshKit();
      } catch (_) {
        // The update has succeeded; the parent page will refresh as well.
      }
      widget.onChanged?.call();
    } catch (e) {
      updateError = e;
    } finally {
      await dialog.hide();
      if (mounted) {
        setState(() {
          _updatingNotice = false;
        });
      }
    }

    if (!mounted) {
      return;
    }
    if (updateError == null) {
      showShortToast(context, context.strings.recoveryTimeUpdated);
    } else if (_isActiveRecoverySessionError(updateError)) {
      try {
        await _refreshKit();
      } catch (_) {
        // The backend rejection is enough to explain the failed update.
      }
      await showAlertBottomSheet(
        context,
        title: context.strings.cannotUpdateRecoveryTime,
        message: context.strings.cannotUpdateRecoveryTimeMessage,
        assetPath: "assets/warning-blue.png",
      );
    } else {
      showShortToast(context, context.strings.somethingWentWrong);
    }
  }

  Future<void> _refreshKit() async {
    final refreshed = await LegacyKitService.instance.getKits();
    final current = refreshed.where((kit) => kit.id == _kit.id).firstOrNull;
    if (current != null && mounted) {
      setState(() {
        _kit = current;
        if (!_kit.hasActiveRecoverySession) {
          _recoveryDetails = null;
        }
      });
    }
  }

  Future<void> _downloadAll() async {
    if (!await _authenticate(context.strings.authToManageLegacyKit)) {
      return;
    }
    final dialog = createProgressDialog(context, context.strings.pleaseWait);
    await dialog.show();
    try {
      final shares = await LegacyKitService.instance.downloadShares(_kit.id);
      final sortedShares = shares.toList(growable: false)
        ..sort((a, b) => a.shareIndex.compareTo(b.shareIndex));
      for (final share in sortedShares) {
        final bytes = await const LegacyKitPdfService().buildRecoverySheet(
          accountEmail: widget.accountEmail,
          share: share,
          allShares: shares,
        );
        await _savePdf(bytes, _kit, part: _partForShare(share));
      }
      await dialog.hide();
      if (mounted) {
        showShortToast(context, context.strings.legacyKitDownloaded);
      }
    } catch (_) {
      await dialog.hide();
      if (mounted) {
        showShortToast(context, context.strings.somethingWentWrong);
      }
    }
  }

  Future<void> _downloadPart(LegacyKitPart part) async {
    if (!await _authenticate(context.strings.authToManageLegacyKit)) {
      return;
    }
    final dialog = createProgressDialog(context, context.strings.pleaseWait);
    await dialog.show();
    try {
      final shares = await LegacyKitService.instance.downloadShares(_kit.id);
      final share = shares.firstWhereOrNull(
        (share) => share.shareIndex == part.index,
      );
      if (share == null) {
        throw StateError("Missing legacy kit share for part ${part.index}");
      }
      final bytes = await const LegacyKitPdfService().buildRecoverySheet(
        accountEmail: widget.accountEmail,
        share: share,
        allShares: shares,
      );
      await _savePdf(bytes, _kit, part: part);
      await dialog.hide();
      if (mounted) {
        showShortToast(context, context.strings.legacyKitSheetDownloaded);
      }
    } catch (_) {
      await dialog.hide();
      if (mounted) {
        showShortToast(context, context.strings.somethingWentWrong);
      }
    }
  }

  Future<void> _deleteKit() async {
    final colorScheme = getEnteColorScheme(context);
    final confirmed = await showAlertBottomSheet<bool>(
      context,
      title: context.strings.deleteLegacyKit,
      message: context.strings.deleteLegacyKitMessage,
      assetPath: "assets/warning-red.png",
      buttons: [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: context.strings.delete,
            backgroundColor: colorScheme.warning700,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
    if (confirmed != true) {
      return;
    }
    if (!await _authenticate(context.strings.authToManageLegacyKit)) {
      return;
    }
    try {
      await LegacyKitService.instance.deleteKit(_kit.id);
      widget.onChanged?.call();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        showShortToast(context, context.strings.somethingWentWrong);
      }
    }
  }

  Future<void> _blockRecovery() async {
    final colorScheme = getEnteColorScheme(context);
    final confirmed = await showAlertBottomSheet<bool>(
      context,
      title: context.strings.rejectRecovery,
      message: context.strings.blockLegacyKitRecoveryMessage,
      assetPath: "assets/warning-red.png",
      buttons: [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: context.strings.rejectRecovery,
            backgroundColor: colorScheme.warning700,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
    if (confirmed != true) {
      return;
    }
    if (!await _authenticate(context.strings.authToManageLegacyKit)) {
      return;
    }
    try {
      await LegacyKitService.instance.blockRecovery(_kit.id);
      final refreshed = await LegacyKitService.instance.getKits();
      final current = refreshed.where((kit) => kit.id == _kit.id).firstOrNull;
      if (current != null && mounted) {
        setState(() {
          _kit = current;
          _recoveryDetails = null;
        });
      }
      widget.onChanged?.call();
    } catch (_) {
      if (mounted) {
        showShortToast(context, context.strings.somethingWentWrong);
      }
    }
  }

  Future<bool> _authenticate(String reason) async {
    final authenticator = widget.authenticator;
    if (authenticator == null) {
      return true;
    }
    return authenticator(context, reason);
  }

  Future<void> _savePdf(
    Uint8List bytes,
    LegacyKit kit, {
    LegacyKitPart? part,
  }) {
    return FileSaverUtil.saveFile(
      _fileNameForKit(kit, part: part),
      "pdf",
      bytes,
      MimeType.pdf,
    );
  }

  LegacyKitPart _partForShare(LegacyKitShare share) {
    return _kit.parts.firstWhereOrNull(
          (part) => part.index == share.shareIndex,
        ) ??
        LegacyKitPart(index: share.shareIndex, name: share.partName);
  }

  String _formatNoticePeriod(int hours) {
    if (hours == 0) {
      return context.strings.immediate;
    }
    if (hours % 24 == 0) {
      return context.strings.nDays(hours ~/ 24);
    }
    return context.strings.nHours(hours);
  }

  bool _isActiveRecoverySessionError(Object error) {
    return error is rust.ContactsError_Http &&
        error.status == 400 &&
        error.message.contains("active recovery session");
  }

  String _fileNameForKit(LegacyKit kit, {LegacyKitPart? part}) {
    final name = part == null
        ? _fileNameComponent(kit.displayName, fallback: kit.id)
        : _fileNameComponent(
            part.name,
            fallback: "part-${part.index}",
          );
    return "ente-recovery-sheet-$name";
  }

  String _fileNameComponent(String value, {required String fallback}) {
    final sanitized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"""[\\/:*?"<>|\x00-\x1F]+"""), "-")
        .replaceAll(RegExp(r"[^a-z0-9]+"), "-")
        .replaceAll(RegExp(r"-+"), "-")
        .replaceAll(RegExp(r"^-+|-+$"), "");
    return sanitized.isEmpty ? fallback : sanitized;
  }
}

class _RecoveryBanner extends StatelessWidget {
  final LegacyKitRecoverySession session;
  final List<LegacyKitPart> parts;
  final bool loadingDetails;
  final LegacyKitOwnerRecoverySessionDetails? details;
  final VoidCallback onBlockRecovery;

  const _RecoveryBanner({
    required this.session,
    required this.parts,
    required this.loadingDetails,
    required this.details,
    required this.onBlockRecovery,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final createdAt = _formatDateTime(session.createdAt);
    final waitTill = _formatWaitTill(session.waitTill);
    final attemptSummaries = details == null
        ? const <_RecoveryAttemptSummary>[]
        : _summarizeAttempts(details!.initiators);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.warning400.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.strings.legacyKitRecoveryInProgress,
            style: textTheme.bodyBold.copyWith(color: colorScheme.warning400),
          ),
          const SizedBox(height: 8),
          Text(
            context.strings.legacyKitRecoveryWindow(createdAt, waitTill),
            style: textTheme.smallMuted,
          ),
          if (!loadingDetails && details != null) ...[
            const SizedBox(height: 8),
            Text(
              context.strings.legacyKitRecoveryAuditHints(
                details!.initiators.length,
              ),
              style: textTheme.smallMuted,
            ),
            if (attemptSummaries.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...attemptSummaries.map(
                (summary) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${summary.sheetNames} • ${_formatAttemptCount(summary.attemptCount)}",
                        style: textTheme.miniMuted,
                      ),
                      Text(
                        "Latest IP: ${summary.latestIP}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.miniMuted,
                      ),
                      Text(
                        "Latest UA: ${summary.latestUserAgent}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.miniMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          GradientButton(
            text: context.strings.rejectRecovery,
            backgroundColor: colorScheme.warning700,
            onTap: () async => onBlockRecovery(),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(int micros) {
    final dateTime = DateTime.fromMicrosecondsSinceEpoch(micros).toLocal();
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }

  String _formatWaitTill(int waitTillMicros) {
    final dateTime = DateTime.now().add(
      Duration(microseconds: waitTillMicros),
    );
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }

  List<_RecoveryAttemptSummary> _summarizeAttempts(
    List<LegacyKitRecoveryInitiatorHint> initiators,
  ) {
    final summaryByKey = <String, _RecoveryAttemptSummary>{};
    for (var index = 0; index < initiators.length; index++) {
      final initiator = initiators[index];
      final partIndexes = initiator.usedPartIndexes.toSet().toList()..sort();
      final key = partIndexes.isEmpty ? "unknown" : partIndexes.join(",");
      final sheetNames = _sheetNames(partIndexes);
      final existing = summaryByKey[key];
      summaryByKey[key] = _RecoveryAttemptSummary(
        sheetNames: sheetNames,
        attemptCount: (existing?.attemptCount ?? 0) + 1,
        latestAttemptIndex: index,
        latestIP: _nonEmptyOrUnknown(initiator.ip),
        latestUserAgent: _nonEmptyOrUnknown(initiator.userAgent),
      );
    }
    return summaryByKey.values.toList()
      ..sort((a, b) => b.latestAttemptIndex.compareTo(a.latestAttemptIndex));
  }

  String _sheetNames(List<int> partIndexes) {
    if (partIndexes.isEmpty) {
      return "Unknown sheets";
    }
    return partIndexes.map((partIndex) {
      final partName = parts
          .firstWhereOrNull((part) => part.index == partIndex)
          ?.name
          .trim();
      return partName == null || partName.isEmpty
          ? "Part $partIndex"
          : partName;
    }).join(" + ");
  }

  String _formatAttemptCount(int count) {
    return count == 1 ? "1 attempt" : "$count attempts";
  }

  String _nonEmptyOrUnknown(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? "Unknown" : trimmed;
  }
}

class _RecoveryAttemptSummary {
  final String sheetNames;
  final int attemptCount;
  final int latestAttemptIndex;
  final String latestIP;
  final String latestUserAgent;

  const _RecoveryAttemptSummary({
    required this.sheetNames,
    required this.attemptCount,
    required this.latestAttemptIndex,
    required this.latestIP,
    required this.latestUserAgent,
  });
}

class _LegacyKitPartRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color cardColor;
  final Color avatarColor;
  final VoidCallback onTap;

  const _LegacyKitPartRow({
    required this.name,
    required this.subtitle,
    required this.cardColor,
    required this.avatarColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _PartInitial(name: name, color: avatarColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textTheme.small.copyWith(height: 20 / 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.mini.copyWith(
                          color: colorScheme.textMuted,
                          height: 16 / 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: Center(
                    child: LegacyKitDownloadIcon(
                      color: colorScheme.textBase,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecoveryWaitTimeRow extends StatelessWidget {
  final String title;
  final String value;
  final bool canEdit;
  final VoidCallback onTap;

  const _RecoveryWaitTimeRow({
    required this.title,
    required this.value,
    required this.canEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final cardColor = colorScheme.isLightTheme
        ? Colors.white
        : colorScheme.backgroundElevated2;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: canEdit ? onTap : null,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  height: 36,
                  width: 36,
                  child: Center(
                    child: LegacyKitClockIcon(
                      color: colorScheme.primary700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.small.copyWith(height: 20 / 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: textTheme.mini.copyWith(
                          color: colorScheme.textMuted,
                          height: 16 / 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: canEdit
                      ? Center(
                          child: LegacyKitEditIcon(
                            color: colorScheme.textBase,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartInitial extends StatelessWidget {
  final String name;
  final Color color;

  const _PartInitial({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final initial = name.trim().isEmpty ? "?" : name.trim()[0].toUpperCase();

    return SizedBox(
      height: 36,
      width: 36,
      child: Center(
        child: Container(
          width: 33,
          height: 33,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: textTheme.mini.copyWith(
                color: Colors.white,
                height: 15 / 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
