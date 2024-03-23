import 'dart:async';
import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/onboarding/view/setup_enter_secret_key_page.dart';
import 'package:ente_auth/onboarding/view/view_qr_page.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/code_timer_progress.dart';
import 'package:ente_auth/ui/utils/icon_utils.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:logging/logging.dart';
import 'package:move_to_background/move_to_background.dart';

class CodeWidget extends StatefulWidget {
  final Code code;

  const CodeWidget(this.code, {super.key});

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

  @override
  void initState() {
    super.initState();
    isMaskingEnabled = PreferenceService.instance.shouldHideCodes();
    _hideCode = isMaskingEnabled;
    _everySecondTimer =
        Timer.periodic(const Duration(milliseconds: 500), (Timer t) {
      String newCode = _getCurrentOTP();
      if (newCode != _currentCode.value) {
        _currentCode.value = newCode;
        if (widget.code.type == Type.totp) {
          _nextCode.value = _getNextTotp();
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
    if (isMaskingEnabled != PreferenceService.instance.shouldHideCodes()) {
      isMaskingEnabled = PreferenceService.instance.shouldHideCodes();
      _hideCode = isMaskingEnabled;
    }
    _shouldShowLargeIcon = PreferenceService.instance.shouldShowLargeIcons();
    if (!_isInitialized) {
      _currentCode.value = _getCurrentOTP();
      if (widget.code.type == Type.totp) {
        _nextCode.value = _getNextTotp();
      }
      _isInitialized = true;
    }
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 8),
      child: Slidable(
        key: ValueKey(widget.code.hashCode),
        endActionPane: ActionPane(
          extentRatio: 0.60,
          motion: const ScrollMotion(),
          children: [
            const SizedBox(
              width: 4,
            ),
            SlidableAction(
              onPressed: _onShowQrPressed,
              backgroundColor: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              foregroundColor:
                  Theme.of(context).colorScheme.inverseBackgroundColor,
              icon: Icons.qr_code_2_outlined,
              label: "QR",
              padding: const EdgeInsets.only(left: 4, right: 0),
              spacing: 8,
            ),
            const SizedBox(
              width: 4,
            ),
            SlidableAction(
              onPressed: _onEditPressed,
              backgroundColor: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              foregroundColor:
                  Theme.of(context).colorScheme.inverseBackgroundColor,
              icon: Icons.edit_outlined,
              label: l10n.edit,
              padding: const EdgeInsets.only(left: 4, right: 0),
              spacing: 8,
            ),
            const SizedBox(
              width: 4,
            ),
            SlidableAction(
              onPressed: _onDeletePressed,
              backgroundColor: Colors.grey.withOpacity(0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              foregroundColor: const Color(0xFFFE4A49),
              icon: Icons.delete,
              label: l10n.delete,
              padding: const EdgeInsets.only(left: 0, right: 0),
              spacing: 8,
            ),
          ],
        ),
        child: Builder(
          builder: (context) {
            return RawGestureDetector(
              gestures: {
                PanGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                  () => PanGestureRecognizer(
                    debugOwner: this,
                    // This recognizer accepts any button press made with a secondary button.
                    allowedButtonsFilter: (int buttons) =>
                        buttons & kSecondaryButton != 0,
                  ),
                  (PanGestureRecognizer instance) {
                    instance
                      ..dragStartBehavior = DragStartBehavior.down
                      ..onEnd = (DragEndDetails details) {
                        Slidable.of(context)?.openEndActionPane();
                      };
                  },
                ),
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Theme.of(context).colorScheme.codeCardBackgroundColor,
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
                      onLongPress: () {
                        _copyCurrentOTPToClipboard();
                      },
                      child: _getCardContents(l10n),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _getCardContents(AppLocalizations l10n) {
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.code.type == Type.totp)
            CodeTimerProgress(
              period: widget.code.period,
            ),
          const SizedBox(
            height: 16,
          ),
          Row(
            children: [
              _shouldShowLargeIcon ? _getIcon() : const SizedBox.shrink(),
              Expanded(
                child: Column(
                  children: [
                    _getTopRow(),
                    const SizedBox(height: 4),
                    _getBottomRow(l10n),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
        ],
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
                  child: Text(
                    _getFormattedCode(value),
                    style: const TextStyle(fontSize: 24),
                  ),
                );
              },
            ),
          ),
          widget.code.type == Type.totp
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
                              style: const TextStyle(
                                fontSize: 18,
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
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                safeDecode(widget.code.issuer).trim(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                safeDecode(widget.code.account).trim(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
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
    return Padding(
      padding: _shouldShowLargeIcon
          ? const EdgeInsets.only(left: 16)
          : const EdgeInsets.all(0),
      child: IconUtils.instance.getIcon(
        context,
        safeDecode(widget.code.issuer).trim(),
        width: _shouldShowLargeIcon ? 42 : 24,
      ),
    );
  }

  void _copyCurrentOTPToClipboard() async {
    _copyToClipboard(
      _getCurrentOTP(),
      confirmationMessage: context.l10n.copiedToClipboard,
    );
  }

  void _copyNextToClipboard() {
    _copyToClipboard(
      _getNextTotp(),
      confirmationMessage: context.l10n.copiedNextToClipboard,
    );
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

  Future<void> _onEditPressed(_) async {
    bool isAuthSuccessful = await LocalAuthenticationService.instance
        .requestLocalAuthentication(context, context.l10n.editCodeAuthMessage);
    await PlatformUtil.refocusWindows();
    if (!isAuthSuccessful) {
      return;
    }
    final Code? code = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return SetupEnterSecretKeyPage(code: widget.code);
        },
      ),
    );
    if (code != null) {
      await CodeStore.instance.addCode(code);
    }
  }

  Future<void> _onShowQrPressed(_) async {
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

  void _onDeletePressed(_) async {
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
        await CodeStore.instance.removeCode(widget.code);
      },
    );
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
      assert(widget.code.type == Type.totp);
      return getNextTotp(widget.code);
    } catch (e) {
      return context.l10n.error;
    }
  }

  String _getFormattedCode(String code) {
    if (_hideCode) {
      // replace all digits with •
      code = code.replaceAll(RegExp(r'\d'), '•');
    }
    if (code.length == 6) {
      return "${code.substring(0, 3)} ${code.substring(3, 6)}";
    }
    return code;
  }
}
