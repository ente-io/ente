import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/extensions/input_formatter.dart";
import "package:photos/models/api/storage_bonus/storage_bonus.dart";
import "package:photos/models/user_details.dart";
import "package:photos/services/storage_bonus_service.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/growth/code_success_screen.dart";
import "package:photos/utils/dialog_util.dart";

class ApplyCodeScreen extends StatefulWidget {
  // referrerView and userDetails used to render code_success_screen
  final ReferralView referralView;
  final UserDetails userDetails;
  const ApplyCodeScreen(
    this.referralView,
    this.userDetails, {
    super.key,
  });

  @override
  State<ApplyCodeScreen> createState() => _ApplyCodeScreenState();
}

class _ApplyCodeScreenState extends State<ApplyCodeScreen> {
  late TextEditingController _textController;

  late FocusNode textFieldFocusNode;
  String code = "";

  @override
  void initState() {
    _textController = TextEditingController();
    textFieldFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textStyle = getEnteTextTheme(context);
    textFieldFocusNode.requestFocus();
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: const TitleBarTitleWidget(
              title: "Apply code",
            ),
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  // Go three screen back, similar to pop thrice
                  Navigator.of(context)
                    ..pop()
                    ..pop()
                    ..pop();
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (delegateBuildContext, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          children: [
                            Text(
                              "Enter the code provided by your friend to "
                              "claim free storage for both of you",
                              style: textStyle.small
                                  .copyWith(color: colorScheme.textMuted),
                            ),
                            const SizedBox(height: 24),
                            _getInputField(),
                            // Container with 8 border radius and red color
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: 1,
            ),
          ),
          SliverFillRemaining(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ButtonWidget(
                      buttonType: ButtonType.neutral,
                      buttonSize: ButtonSize.large,
                      labelText: "Apply",
                      isDisabled: code.trim().length < 4,
                      onTap: () async {
                        try {
                          await StorageBonusService.instance
                              .getGateway()
                              .claimReferralCode(code.trim().toUpperCase());

                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => CodeSuccessScreen(
                                widget.referralView,
                                widget.userDetails,
                              ),
                            ),
                          );
                        } catch (e) {
                          Logger('$runtimeType')
                              .severe("failed to apply referral", e);
                          showErrorDialogForException(
                            context: context,
                            exception: e as Exception,
                            apiErrorPrefix: "Failed to apply code",
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getInputField() {
    return TextFormField(
      controller: _textController,
      focusNode: textFieldFocusNode,
      style: getEnteTextTheme(context).body,
      inputFormatters: [UpperCaseTextFormatter()],
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          borderSide:
              BorderSide(color: getEnteColorScheme(context).strokeMuted),
        ),
        fillColor: getEnteColorScheme(context).fillFaint,
        filled: true,
        hintText: 'Enter referral code',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (value) {
        code = value.trim();
        setState(() {});
      },
      autocorrect: false,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
    );
  }
}
