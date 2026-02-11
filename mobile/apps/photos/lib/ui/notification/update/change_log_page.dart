import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/notification/update/change_log_entry.dart';
import 'package:photos/ui/notification/update/change_log_strings.dart';

class ChangeLogPage extends StatefulWidget {
  const ChangeLogPage({
    super.key,
  });

  @override
  State<ChangeLogPage> createState() => _ChangeLogPageState();
}

class _ChangeLogPageState extends State<ChangeLogPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    return Material(
      color: enteColorScheme.backgroundElevated,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 36),
          Container(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TitleBarTitleWidget(
                title: AppLocalizations.of(context).whatsNew,
              ),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Flexible(child: _getChangeLog(context)),
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
                    labelText: AppLocalizations.of(context).continueLabel,
                    icon: Icons.arrow_forward_outlined,
                    onTap: () async {
                      await updateService.hideChangeLog();
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ButtonWidget(
                    buttonType: ButtonType.trailingIconSecondary,
                    buttonSize: ButtonSize.large,
                    labelText: AppLocalizations.of(context).rateUs,
                    icon: Icons.favorite_rounded,
                    iconColor: enteColorScheme.primary500,
                    onTap: () async {
                      await updateService.launchReviewUrl();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getChangeLog(BuildContext ctx) {
    final strings = ChangeLogStrings.forLocale(Localizations.localeOf(context));
    final List<ChangeLogEntry> items = [];
    items.addAll([
      ChangeLogEntry(
        strings.title1,
        description: strings.desc1,
        items: [
          strings.desc1Item1,
          strings.desc1Item2,
        ],
        isFeature: true,
      ),
      ChangeLogEntry(
        strings.title2,
        description: strings.desc2,
        isFeature: true,
      ),
      ChangeLogEntry(
        strings.title3,
        description: strings.desc3,
        isFeature: true,
      ),
    ]);
    return Container(
      padding: const EdgeInsets.only(left: 16),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 2.0,
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
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
