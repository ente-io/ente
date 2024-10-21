import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/user_remote_flag_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/web_page.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/utils/dialog_util.dart";

class EnableMachineLearningConsent extends StatefulWidget {
  const EnableMachineLearningConsent({super.key});

  @override
  State<EnableMachineLearningConsent> createState() =>
      _EnableMachineLearningConsentState();
}

class _EnableMachineLearningConsentState
    extends State<EnableMachineLearningConsent> {
  final ValueNotifier<bool> _hasAckedPrivacyPolicy = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _hasAckedPrivacyPolicy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).mlConsentTitle,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (delegateBuildContext, index) => Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Column(
                  children: [
                    Text(
                      S.of(context).mlConsentDescription,
                      textAlign: TextAlign.left,
                      style: getEnteTextTheme(context).body.copyWith(
                            color: getEnteColorScheme(context).textMuted,
                          ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) {
                              return WebPage(
                                S.of(context).privacyPolicyTitle,
                                "https://ente.io/privacy",
                              );
                            },
                          ),
                        );
                      },
                      child: Text(
                        S.of(context).mlConsentPrivacy,
                        textAlign: TextAlign.left,
                        style: getEnteTextTheme(context).body.copyWith(
                              color: getEnteColorScheme(context).textMuted,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _hasAckedPrivacyPolicy.value,
                          side: CheckboxTheme.of(context).side,
                          onChanged: (value) {
                            setState(() {
                              _hasAckedPrivacyPolicy.value = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              S.of(context).mlConsentConfirmation,
                              style: getEnteTextTheme(context).bodyMuted,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    ButtonWidget(
                      buttonType: ButtonType.primary,
                      labelText: S.of(context).mlConsent,
                      isDisabled: _hasAckedPrivacyPolicy.value == false,
                      onTap: () async {
                        await enableMlConsent(context);
                      },
                      shouldSurfaceExecutionStates: true,
                    ),
                    const SizedBox(height: 12),
                    ButtonWidget(
                      buttonType: ButtonType.secondary,
                      labelText: S.of(context).cancel,
                      onTap: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                    const SafeArea(
                      child: SizedBox(
                        height: 12,
                      ),
                    ),
                  ],
                ),
              ),
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> enableMlConsent(BuildContext context) async {
    try {
      await userRemoteFlagService.setBoolValue(
        UserRemoteFlagService.mlEnabled,
        true,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      // ignore: unawaited_futures
      showGenericErrorDialog(
        context: context,
        error: e,
      );
    }
  }
}
