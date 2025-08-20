import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:clipboard/clipboard.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/onboarding/view/setup_enter_secret_key_page.dart';
import 'package:ente_auth/onboarding/view/view_qr_page.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/code_timer_progress.dart';
import 'package:ente_auth/ui/components/bottom_action_bar_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/ui/share/code_share.dart';
import 'package:ente_auth/ui/utils/icon_utils.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:ente_lock_screen/local_authentication_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logging/logging.dart';
import 'package:move_to_background/move_to_background.dart';

class CodeWidget extends StatefulWidget {
  final Code code;
  final bool isCompactMode;
  final CodeSortKey? sortKey;
  final bool isReordering;

  const CodeWidget(
    this.code, {
    super.key,
    required this.isCompactMode,
    this.sortKey,
    this.isReordering = false,
  });

  @override
  State<CodeWidget> createState() => _CodeWidgetState();
}

class _CodeWidgetState extends State<CodeWidget> {
  Timer? _everySecondTimer;
  final ValueNotifier<String> _currentCode = ValueNotifier<String>("");
  final ValueNotifier<String> _nextCode = ValueNotifier<String>("");
  final Logger logger = Logger("_CodeWidgetState");
  bool _isInitialized = false;
  late bool hasConfiguredAccount;
  late bool _shouldShowLargeIcon;
  late bool _hideCode;
  bool isMaskingEnabled = false;
  int _codeTimeStep = -1;
  int lastRefreshTime = 0;
  bool ignorePin = false;

  @override
  void initState() {
    super.initState();
    isMaskingEnabled = PreferenceService.instance.shouldHideCodes();

    _hideCode = isMaskingEnabled;
    _everySecondTimer =
        Timer.periodic(const Duration(milliseconds: 500), (Timer t) {
      int newStep = 0;
      int epochSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (widget.code.type != Type.hotp) {
        newStep = ((epochSeconds.round()) ~/ widget.code.period).floor();
      } else {
        newStep = widget.code.counter;
      }
      if (_codeTimeStep != newStep ||
          epochSeconds - lastRefreshTime > widget.code.period) {
        String newCode = _getCurrentOTP();
        if (newCode != _currentCode.value && mounted) {
          _currentCode.value = newCode;
          if (widget.code.type.isTOTPCompatible) {
            _nextCode.value = _getNextTotp();
          }
          _codeTimeStep = newStep;
          lastRefreshTime = epochSeconds;
        }
      }
    });
    hasConfiguredAccount = Configuration.instance.hasConfiguredAccount();
  }

  @override
  void dispose() {
    _everySecondTimer?.cancel();
    _currentCode.dispose();
    _nextCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ignorePin = widget.sortKey != null && widget.sortKey == CodeSortKey.manual;
    final colorScheme = getEnteColorScheme(context);
    if (isMaskingEnabled != PreferenceService.instance.shouldHideCodes()) {
      isMaskingEnabled = PreferenceService.instance.shouldHideCodes();
      _hideCode = isMaskingEnabled;
    }
    _shouldShowLargeIcon = PreferenceService.instance.shouldShowLargeIcons();
    if (!_isInitialized) {
      _currentCode.value = _getCurrentOTP();
      if (widget.code.type.isTOTPCompatible) {
        _nextCode.value = _getNextTotp();
      }
      _isInitialized = true;
    }
    final l10n = context.l10n;

    Widget getCardContents(AppLocalizations l10n) {
      return Stack(
        children: [
          if (!ignorePin && widget.code.isPinned)
            Align(
              alignment: Alignment.topRight,
              child: CustomPaint(
                painter: PinBgPainter(
                  color: colorScheme.pinnedBgColor,
                ),
                size: widget.isCompactMode
                    ? const Size(24, 24)
                    : const Size(39, 39),
              ),
            ),
          if (widget.code.isTrashed && kDebugMode)
            Align(
              alignment: Alignment.topLeft,
              child: CustomPaint(
                painter: PinBgPainter(
                  color: colorScheme.warning700,
                ),
                size: const Size(39, 39),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.code.type.isTOTPCompatible)
                CodeTimerProgress(
                  key: ValueKey('period_${widget.code.period}'),
                  period: widget.code.period,
                  isCompactMode: widget.isCompactMode,
                  timeOffsetInMilliseconds:
                      PreferenceService.instance.timeOffsetInMilliSeconds(),
                ),
              widget.isCompactMode
                  ? const SizedBox(height: 4)
                  : const SizedBox(height: 28),
              Row(
                children: [
                  _shouldShowLargeIcon ? _getIcon() : const SizedBox.shrink(),
                  Expanded(
                    child: Column(
                      children: [
                        _getTopRow(),
                        widget.isCompactMode
                            ? const SizedBox.shrink()
                            : const SizedBox(height: 4),
                        _getBottomRow(l10n),
                      ],
                    ),
                  ),
                ],
              ),
              widget.isCompactMode
                  ? const SizedBox(height: 4)
                  : const SizedBox(height: 32),
            ],
          ),
          if (!ignorePin && widget.code.isPinned) ...[
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: widget.isCompactMode
                    ? const EdgeInsets.only(right: 4, top: 4)
                    : const EdgeInsets.only(right: 6, top: 6),
                child: SvgPicture.asset(
                  "assets/svg/pin-card.svg",
                  width: widget.isCompactMode ? 8 : null,
                  height: widget.isCompactMode ? 8 : null,
                ),
              ),
            ),
          ],
        ],
      );
    }

    Widget clippedCard(AppLocalizations l10n) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.codeCardBackgroundColor,
          boxShadow:
              widget.code.isPinned ? colorScheme.pinnedCardBoxShadow : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () {
                _copyCurrentOTPToClipboard();
              },
              onDoubleTap: isMaskingEnabled
                  ? () {
                      setState(
                        () {
                          _hideCode = !_hideCode;
                        },
                      );
                    }
                  : null,
              onLongPress: widget.isReordering
                  ? null
                  : () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) {
                          return BottomActionBarWidget(
                            code: widget.code,
                            showPin: !ignorePin,
                            onEdit: () => _onEditPressed(true),
                            onShare: () => _onSharePressed(true),
                            onPin: () => _onPinPressed(true),
                            onTrashed: () => _onTrashPressed(true),
                            onDelete: () => _onDeletePressed(true),
                            onRestore: () => _onRestoreClicked(true),
                            onShowQR: () => _onShowQrPressed(true),
                            onCancel: () => Navigator.of(context).pop(),
                          );
                        },
                      );
                    },
              child: getCardContents(l10n),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: widget.isCompactMode
          ? const EdgeInsets.only(left: 16, right: 16, bottom: 6, top: 6)
          : const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 8),
      child: Builder(
        builder: (context) {
          if (PlatformUtil.isDesktop()) {
            return ContextMenuRegion(
              contextMenu: ContextMenu(
                entries: <ContextMenuEntry>[
                  if (!widget.code.isTrashed &&
                      widget.code.type.isTOTPCompatible)
                    MenuItem(
                      label: context.l10n.share,
                      icon: Icons.adaptive.share_outlined,
                      onSelected: () => _onSharePressed(null),
                    ),
                  if (!widget.code.isTrashed)
                    MenuItem(
                      label: 'QR',
                      icon: Icons.qr_code_2_outlined,
                      onSelected: () => _onShowQrPressed(null),
                    ),
                  if (widget.code.note.isNotEmpty)
                    MenuItem(
                      label: context.l10n.notes,
                      icon: Icons.notes_outlined,
                      onSelected: () => _onShowNotesPressed(null),
                    ),
                  if (!widget.code.isTrashed && !ignorePin)
                    MenuItem(
                      label:
                          widget.code.isPinned ? l10n.unpinText : l10n.pinText,
                      icon: widget.code.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      onSelected: () => _onPinPressed(null),
                    ),
                  if (!widget.code.isTrashed)
                    MenuItem(
                      label: l10n.edit,
                      icon: Icons.edit,
                      onSelected: () => _onEditPressed(null),
                    )
                  else
                    MenuItem(
                      label: l10n.restore,
                      icon: Icons.restore_outlined,
                      onSelected: () => _onRestoreClicked(null),
                    ),
                  const MenuDivider(),
                  MenuItem(
                    label: widget.code.isTrashed ? l10n.delete : l10n.trash,
                    value: "Delete",
                    icon: widget.code.isTrashed
                        ? Icons.delete_forever
                        : Icons.delete,
                    onSelected: () => widget.code.isTrashed
                        ? _onDeletePressed(null)
                        : _onTrashPressed(null),
                  ),
                ],
                padding: const EdgeInsets.all(8.0),
              ),
              child: clippedCard(l10n),
            );
          }

          return clippedCard(l10n);
        },
      ),
    );
  }

  Widget _getBottomRow(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _currentCode,
              builder: (context, value, child) {
                return Material(
                  type: MaterialType.transparency,
                  child: AutoSizeText(
                    _getFormattedCode(value),
                    style: TextStyle(fontSize: widget.isCompactMode ? 14 : 24),
                    maxLines: 1,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          widget.code.type.isTOTPCompatible
              ? GestureDetector(
                  onTap: () {
                    _copyNextToClipboard();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.nextTotpTitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: _nextCode,
                        builder: (context, value, child) {
                          return Material(
                            type: MaterialType.transparency,
                            child: Text(
                              _getFormattedCode(value),
                              style: TextStyle(
                                fontSize: widget.isCompactMode ? 12 : 18,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.nextTotpTitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    InkWell(
                      onTap: _onNextHotpTapped,
                      child: const Icon(
                        Icons.forward_outlined,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _getTopRow() {
    bool isCompactMode = widget.isCompactMode;
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safeDecode(widget.code.issuer).trim(),
                  style: isCompactMode
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.titleLarge,
                ),
                if (!isCompactMode) const SizedBox(height: 2),
                Text(
                  safeDecode(widget.code.account).trim(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: isCompactMode ? 12 : 12,
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              (widget.code.hasSynced != null && widget.code.hasSynced!) ||
                      !hasConfiguredAccount
                  ? const SizedBox.shrink()
                  : const Icon(
                      Icons.sync_disabled,
                      size: 20,
                      color: Colors.amber,
                    ),
              const SizedBox(width: 12),
              _shouldShowLargeIcon ? const SizedBox.shrink() : _getIcon(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getIcon() {
    final String iconData;
    if (widget.code.display.isCustomIcon) {
      iconData = widget.code.display.iconID;
    } else {
      iconData = widget.code.issuer;
    }
    return Padding(
      padding: _shouldShowLargeIcon
          ? EdgeInsets.only(left: widget.isCompactMode ? 12 : 16)
          : const EdgeInsets.all(0),
      child: IconUtils.instance.getIcon(
        context,
        safeDecode(iconData).trim(),
        width: widget.isCompactMode
            ? (_shouldShowLargeIcon ? 32 : 24)
            : (_shouldShowLargeIcon ? 42 : 24),
      ),
    );
  }

  void _copyCurrentOTPToClipboard() {
    _copyToClipboard(
      _getCurrentOTP(),
      confirmationMessage: context.l10n.copiedToClipboard,
    );
    _udateCodeMetadata().ignore();
  }

  void _copyNextToClipboard() {
    _copyToClipboard(
      _getNextTotp(),
      confirmationMessage: context.l10n.copiedNextToClipboard,
    );
    _udateCodeMetadata().ignore();
  }

  Future<void> _udateCodeMetadata() async {
    if (widget.sortKey == null) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        if (widget.sortKey == CodeSortKey.mostFrequentlyUsed ||
            widget.sortKey == CodeSortKey.recentlyUsed) {
          final display = widget.code.display;
          final Code code = widget.code.copyWith(
            display: display.copyWith(
              tapCount: display.tapCount + 1,
              lastUsedAt: DateTime.now().microsecondsSinceEpoch,
            ),
          );
          unawaited(CodeStore.instance.addCode(code));
        }
      }
    });
  }

  void _copyToClipboard(
    String content, {
    required String confirmationMessage,
  }) async {
    final shouldMinimizeOnCopy =
        PreferenceService.instance.shouldMinimizeOnCopy();

    await FlutterClipboard.copy(content);
    showToast(context, confirmationMessage);
    if (Platform.isAndroid && shouldMinimizeOnCopy) {
      // ignore: unawaited_futures
      MoveToBackground.moveTaskToBack();
    }
  }

  void _onNextHotpTapped() {
    if (widget.code.type == Type.hotp) {
      CodeStore.instance
          .addCode(
            widget.code.copyWith(counter: widget.code.counter + 1),
            shouldSync: true,
          )
          .ignore();
    }
  }

  Future<void> _onShowNotesPressed([bool? pop]) async {
    if (mounted && pop == true) {
      Navigator.of(context).pop();
    }
    await showChoiceDialog(
      context,
      title: context.l10n.notes,
      body: widget.code.note,
      firstButtonLabel: context.l10n.close,
      firstButtonType: ButtonType.secondary,
      secondButtonLabel: null,
    );
  }

  Future<void> _onEditPressed([bool? pop]) async {
    if (mounted && pop == true) {
      Navigator.of(context).pop();
    }
    bool isAuthSuccessful = await LocalAuthenticationService.instance
        .requestLocalAuthentication(context, context.l10n.editCodeAuthMessage);
    await PlatformUtil.refocusWindows();
    if (!isAuthSuccessful) {
      return;
    }
    final Code? code = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return SetupEnterSecretKeyPage(
            code: widget.code,
          );
        },
      ),
    );
    if (code != null) {
      await CodeStore.instance.addCode(code);
    }
  }

  Future<void> _onShowQrPressed([bool? pop]) async {
    if (mounted && pop == true) {
      Navigator.of(context).pop();
    }
    bool isAuthSuccessful = await LocalAuthenticationService.instance
        .requestLocalAuthentication(context, context.l10n.showQRAuthMessage);
    await PlatformUtil.refocusWindows();
    if (!isAuthSuccessful) {
      return;
    }
    // ignore: unused_local_variable
    final Code? code = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return ViewQrPage(code: widget.code);
        },
      ),
    );
  }

  Future<void> _onSharePressed([bool? pop]) async {
    if (mounted && pop == true) {
      Navigator.of(context).pop();
    }
    bool isAuthSuccessful = await LocalAuthenticationService.instance
        .requestLocalAuthentication(context, context.l10n.authenticateGeneric);
    await PlatformUtil.refocusWindows();
    if (!isAuthSuccessful) {
      return;
    }
    showShareDialog(context, widget.code);
  }

  Future<void> _onPinPressed([bool? pop]) async {
    if (mounted && pop == true) {
      Navigator.of(context).pop();
    }
    bool currentlyPinned = widget.code.isPinned;
    final display = widget.code.display;
    final Code code = widget.code.copyWith(
      display: display.copyWith(pinned: !currentlyPinned),
    );
    unawaited(
      CodeStore.instance.addCode(code).then(
            (value) => showToast(
              context,
              !currentlyPinned
                  ? context.l10n.pinnedCodeMessage(widget.code.issuer)
                  : context.l10n.unpinnedCodeMessage(widget.code.issuer),
            ),
          ),
    );
  }

  void _onDeletePressed([bool? pop]) async {
    if (mounted && pop == true) {
      Navigator.of(context).pop();
    }
    if (!widget.code.isTrashed) {
      showToast(context, 'Code can only be deleted from trash');
      return;
    }
    bool isAuthSuccessful =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      context.l10n.deleteCodeAuthMessage,
    );
    if (!isAuthSuccessful) {
      return;
    }
    FocusScope.of(context).requestFocus();
    final l10n = context.l10n;
    await showChoiceActionSheet(
      context,
      title: l10n.deleteCodeTitle,
      body: l10n.deleteCodeMessage,
      firstButtonLabel: l10n.delete,
      isCritical: true,
      firstButtonOnTap: () async {
        try {
          await CodeStore.instance.removeCode(widget.code);
        } catch (e, s) {
          logger.severe('Failed to delete code', e, s);
          showGenericErrorDialog(context: context, error: e).ignore();
        }
      },
    );
  }

  void _onTrashPressed([bool? pop]) async {
    if (mounted && pop == true) {
      Navigator.of(context).pop();
    }
    if (widget.code.isTrashed) {
      showToast(context, 'Code is already trashed');
      return;
    }
    bool isAuthSuccessful =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      context.l10n.deleteCodeAuthMessage,
    );
    if (!isAuthSuccessful) {
      return;
    }
    FocusScope.of(context).requestFocus();
    final l10n = context.l10n;
    final String issuerAccount = widget.code.account.isNotEmpty
        ? '${widget.code.issuer} (${widget.code.account})'
        : widget.code.issuer;
    await showChoiceActionSheet(
      context,
      title: l10n.trashCode,
      body: l10n.trashCodeMessage(issuerAccount),
      firstButtonLabel: l10n.trash,
      isCritical: true,
      firstButtonOnTap: () async {
        try {
          final display = widget.code.display;
          final Code code = widget.code.copyWith(
            display: display.copyWith(trashed: true),
          );
          await CodeStore.instance.addCode(code);
        } catch (e) {
          logger.severe('Failed to trash code: ${e.toString()}');
          showGenericErrorDialog(context: context, error: e).ignore();
        }
      },
    );
  }

  void _onRestoreClicked([bool? pop]) async {
    if (mounted && pop == true) {
      Navigator.of(context).pop();
    }
    if (!widget.code.isTrashed) {
      showToast(context, 'Code is already restored');
      return;
    }
    FocusScope.of(context).requestFocus();

    try {
      final display = widget.code.display;
      final Code code = widget.code.copyWith(
        display: display.copyWith(trashed: false),
      );
      await CodeStore.instance.addCode(code);
    } catch (e) {
      logger.severe('Failed to restore code: ${e.toString()}');
      if (mounted) {
        showGenericErrorDialog(context: context, error: e).ignore();
      }
    }
  }

  String _getCurrentOTP() {
    try {
      return getOTP(widget.code);
    } catch (e) {
      return context.l10n.error;
    }
  }

  String _getNextTotp() {
    try {
      assert(widget.code.type.isTOTPCompatible);
      return getNextTotp(widget.code);
    } catch (e) {
      return context.l10n.error;
    }
  }

  String _getFormattedCode(String code) {
    if (_hideCode) {
      // replace all digits with •
      code = code.replaceAll(RegExp(r'\S'), '•');
    }
    switch (code.length) {
      case 6:
        return "${code.substring(0, 3)} ${code.substring(3, 6)}";
      case 7:
        return "${code.substring(0, 3)} ${code.substring(3, 4)} ${code.substring(4, 7)}";
      case 8:
        return "${code.substring(0, 3)} ${code.substring(3, 5)} ${code.substring(5, 8)}";
      case 9:
        return "${code.substring(0, 3)} ${code.substring(3, 6)} ${code.substring(6, 9)}";
      default:
        return code;
    }
  }
}

class PinBgPainter extends CustomPainter {
  final Color color;
  final PaintingStyle paintingStyle;

  PinBgPainter({
    this.color = Colors.black,
    this.paintingStyle = PaintingStyle.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = paintingStyle;

    canvas.drawPath(getTrianglePath(size.width, size.height), paint);
  }

  Path getTrianglePath(double x, double y) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(x, 0)
      ..lineTo(x, y)
      ..lineTo(0, 0);
  }

  @override
  bool shouldRepaint(PinBgPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.paintingStyle != paintingStyle;
  }
}
