import "package:dio/dio.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/storage_bonus/storage_bonus.dart";
import "package:photos/models/user_details.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/base_bottom_sheet.dart";
import "package:photos/ui/growth/code_success_screen.dart";

Future<bool?> showApplyCodeSheet(
  BuildContext context, {
  required ReferralView referralView,
  required UserDetails userDetails,
}) {
  return showBaseBottomSheet<bool>(
    context,
    title: AppLocalizations.of(context).applyCodeTitle,
    headerSpacing: 20,
    child: _ApplyCodeContent(
      referralView: referralView,
      userDetails: userDetails,
    ),
  );
}

class _ApplyCodeContent extends StatefulWidget {
  final ReferralView referralView;
  final UserDetails userDetails;

  const _ApplyCodeContent({
    required this.referralView,
    required this.userDetails,
  });

  @override
  State<_ApplyCodeContent> createState() => _ApplyCodeContentState();
}

class _ApplyCodeContentState extends State<_ApplyCodeContent> {
  late TextEditingController _controller;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _errorMessage = null;
    });
  }

  bool get _isValid => _controller.text.trim().length >= 4;

  Future<void> _applyCode() async {
    final code = _controller.text.trim();
    if (code.length < 4) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await storageBonusService.applyCode(code);
      if (mounted) {
        Navigator.of(context).pop(true);
        // Navigate to success screen
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CodeSuccessScreen(
              widget.referralView,
              widget.userDetails,
            ),
          ),
        );
      }
    } catch (e) {
      Logger("ApplyCodeSheet").severe("Failed to apply code", e);
      if (mounted) {
        String errorMessage = AppLocalizations.of(context).failedToApplyCode;
        if (e is DioException &&
            e.response != null &&
            e.response!.data != null) {
          final code = e.response!.data["code"];
          if (code == "INVALID_CODE") {
            errorMessage = AppLocalizations.of(context).invalidReferralCode;
          } else if (code != null) {
            errorMessage =
                "${AppLocalizations.of(context).failedToApplyCode}: $code";
          }
        }
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final inputBackgroundColor =
        isDarkMode ? const Color(0xFF1C1C1C) : const Color(0xFFFAFAFA);

    const greenColor = Color(0xFF08C225);
    const warningRedColor = Color(0xFFF63A3A);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text input field
        Container(
          decoration: BoxDecoration(
            color: inputBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: _controller,
            inputFormatters: [UpperCaseTextFormatter()],
            textCapitalization: TextCapitalization.characters,
            style: textTheme.body,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              hintText: AppLocalizations.of(context).enterReferralCode,
              hintStyle: textTheme.body.copyWith(color: colorScheme.textMuted),
            ),
          ),
        ),
        const SizedBox(height: 9),
        // Helper/error text
        Text(
          _errorMessage ?? AppLocalizations.of(context).enterCodeDescription,
          style: textTheme.mini.copyWith(
            color: _errorMessage != null ? warningRedColor : colorScheme.textMuted,
          ),
        ),
        const SizedBox(height: 20),
        // Apply button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading || !_isValid ? null : _applyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isValid ? greenColor : colorScheme.fillMuted,
              foregroundColor: Colors.white,
              disabledBackgroundColor: colorScheme.fillMuted,
              disabledForegroundColor: colorScheme.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.textMuted,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context).apply,
                    style: textTheme.bodyBold.copyWith(
                      color: _isValid ? Colors.white : colorScheme.textMuted,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
