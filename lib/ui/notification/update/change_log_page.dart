import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/services/update_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/notification/update/change_log_entry.dart';
import "package:url_launcher/url_launcher_string.dart";

class ChangeLogPage extends StatefulWidget {
  const ChangeLogPage({
    Key? key,
  }) : super(key: key);

  @override
  State<ChangeLogPage> createState() => _ChangeLogPageState();
}

class _ChangeLogPageState extends State<ChangeLogPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    return Scaffold(
      appBar: null,
      body: Container(
        color: enteColorScheme.backgroundElevated,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 36,
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: TitleBarTitleWidget(
                  title: "What's new",
                ),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            Expanded(child: _getChangeLog()),
            const DividerWidget(
              dividerType: DividerType.solid,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16,
                  top: 16,
                  bottom: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconPrimary,
                      buttonSize: ButtonSize.large,
                      labelText: S.of(context).continueLabel,
                      icon: Icons.arrow_forward_outlined,
                      onTap: () async {
                        await UpdateService.instance.hideChangeLog();
                        if (mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    // ButtonWidget(
                    //   buttonType: ButtonType.trailingIconSecondary,
                    //   buttonSize: ButtonSize.large,
                    //   labelText: S.of(context).rateTheApp,
                    //   icon: Icons.favorite_rounded,
                    //   iconColor: enteColorScheme.primary500,
                    //   onTap: () async {
                    //     await UpdateService.instance.launchReviewUrl();
                    //   },
                    // ),
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconSecondary,
                      buttonSize: ButtonSize.large,
                      labelText: "Join the ente community",
                      icon: Icons.people_alt_rounded,
                      iconColor: enteColorScheme.primary500,
                      onTap: () async {
                        launchUrlString(
                          "https://ente.io/community",
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getChangeLog() {
    final scrollController = ScrollController();
    final List<ChangeLogEntry> items = [];
    items.add(
      ChangeLogEntry(
        "Hidden albums ✨",
        'You can now hide albums, just like individual memories.\n',
      ),
    );
    items.add(
      ChangeLogEntry(
          "Album improvements ✨",
          'You can now pin your favourite albums, and set cover photos for them.\n'
              '\nWe have also added a way to first create empty albums, and then add photos to it, both from ente and your device gallery.\n'),
    );

    items.add(
      ChangeLogEntry(
        "Email verification ✨",
        'We have now made email verification optional, so you can sign in with'
            ' just your email address and password, without waiting for a verification code.\n'
            '\nYou can opt in / out of email verification from Settings > Security.\n',
      ),
    );

    items.add(
      ChangeLogEntry(
        "Bug fixes & other enhancements",
        'We have squashed a few pesky bugs that were reported by our community,'
            'and have improved the experience for albums and quick links.\n'
            '\nIf you would like to help us improve ente, come join the ente community!',
        isFeature: false,
      ),
    );
    return Container(
      padding: const EdgeInsets.only(left: 16),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        thickness: 2.0,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ChangeLogEntryWidget(entry: items[index]),
            );
          },
          itemCount: items.length,
        ),
      ),
    );
  }
}
