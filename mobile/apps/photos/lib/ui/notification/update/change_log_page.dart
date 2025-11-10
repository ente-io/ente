import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/notification/update/change_log_entry.dart';

class ChangeLogPage extends StatefulWidget {
  const ChangeLogPage({
    super.key,
  });

  @override
  State<ChangeLogPage> createState() => _ChangeLogPageState();
}

class _ChangeLogPageState extends State<ChangeLogPage> {
  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    return Material(
      color: enteColorScheme.backgroundElevated,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TitleBarTitleWidget(
                  title: AppLocalizations.of(context).whatsNew,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _getChangeLog(context),
            ),
            const DividerWidget(
              dividerType: DividerType.solid,
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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

  Widget _getChangeLog(BuildContext ctx) {
    final scrollController = ScrollController();
    final List<ChangeLogEntry> items = [
      ChangeLogEntry(
        context.l10n.cLTitle1,
        context.l10n.cLDesc1,
        isFeature: true,
      ),
      ChangeLogEntry(
        context.l10n.cLTitle2,
        context.l10n.cLDesc2,
        isFeature: true,
      ),
    ];
    final double maxListHeight = MediaQuery.of(ctx).size.height * 0.5;
    final bool shouldScroll = items.length > 3;
    final listView = ListView.builder(
      controller: scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.only(right: 16),
      physics: shouldScroll
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return ChangeLogEntryWidget(entry: items[index]);
      },
      itemCount: items.length,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxListHeight,
      ),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: shouldScroll,
        thickness: 2.0,
        child: listView,
      ),
    );
  }
}
