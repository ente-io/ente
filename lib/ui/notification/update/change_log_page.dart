import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/notification/update/change_log_entry.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
                      labelText: "Continue",
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
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconSecondary,
                      buttonSize: ButtonSize.large,
                      labelText: "Rate the app",
                      icon: Icons.favorite_rounded,
                      iconColor: enteColorScheme.primary500,
                      onTap: () async {
                        launchUrlString(
                          UpdateService.instance.getRateDetails().item2,
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
        "Collect photos from anyone!",
        "You can now enable \"Allow adding photos\" under shared link "
            "settings to allow anyone with access to the link to also add "
            "photos to that shared album.\n\nThis is the perfect fit for "
            "occasions where you want to ask all your friends and relatives who attended the event to add the photos they took to an album. You can then prune them there; plus everyone can view them in a single place.",
      ),
    );
    items.add(
      ChangeLogEntry(
        '''Customize photo grid size''',
        "You can now change the number of photos that are shown in a row."
            "\n\nSince this was a much requested feature we've released it as "
            "an option in Settings > General > Advanced; later we'll also try a gesture for easier access.",
      ),
    );

    items.add(
      ChangeLogEntry(
        '''Better multi-select, and hide''',
        "The item selector gets a new, expanded look with clearly marked "
            "actions. We'll use this revamped space to show even more actions"
            " you can take on selected photos.\n\nAnd we've already added new "
            "actions! You can now select multiple items and hide all of them in one go.",
      ),
    );
    items.add(
      ChangeLogEntry(
        '''Per album free up space''',
        "There is now an option to free up space within each on device album. This provides both a more granular, and faster, way to save storage your phone.",
      ),
    );

    items.add(
      ChangeLogEntry(
        '''Longer photo descriptions''',
        "The previous 280 character limit on photo captions and descriptions has been increased to 5000.",
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
