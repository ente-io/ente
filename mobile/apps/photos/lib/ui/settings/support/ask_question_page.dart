import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/components/text_input_widget_v2.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/settings/support/no_mail_app_sheet.dart";
import "package:photos/utils/email_util.dart";

class AskQuestionPage extends StatefulWidget {
  const AskQuestionPage({super.key});

  @override
  State<AskQuestionPage> createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> {
  static final _logger = Logger("AskQuestionPage");
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.strokeBase,
                  size: 24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.askAQuestion,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextInputWidgetV2(
                        label: l10n.subject,
                        hintText: l10n.yourQuestion,
                        textEditingController: _subjectController,
                        textCapitalization: TextCapitalization.sentences,
                        isClearable: true,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 16),
                      TextInputWidgetV2(
                        label: l10n.description,
                        hintText: l10n.anyAdditionalInformation,
                        textEditingController: _descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 6,
                        minLines: 6,
                      ),
                      const SizedBox(height: 24),
                      ButtonWidgetV2(
                        buttonType: ButtonTypeV2.primary,
                        labelText: l10n.send,
                        isDisabled: _isSending,
                        shouldSurfaceExecutionStates: false,
                        onTap: _onSend,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSend() async {
    if (_isSending) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();
    if (subject.isEmpty) {
      showShortToast(context, l10n.pleaseEnterASubject);
      return;
    }
    if (description.isEmpty) {
      showShortToast(context, l10n.pleaseEnterADescription);
      return;
    }

    setState(() {
      _isSending = true;
    });

    final emailSubject = "[Support] $subject";
    try {
      final didOpenComposer = await sendComposedEmail(
        context,
        to: supportEmail,
        subject: emailSubject,
        body: description,
      );
      if (!didOpenComposer && mounted) {
        await showNoMailAppSheet(
          context,
          toEmail: supportEmail,
          subject: emailSubject,
          message: description,
        );
      }
    } catch (e, s) {
      _logger.severe("Failed to send question to support", e, s);
      if (mounted) {
        showShortToast(context, l10n.somethingWentWrong);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}
