import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/storage_bonus/bonus.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/utils/standalone/data.dart";

class AddOnPage extends StatelessWidget {
  final BonusData bonusData;

  const AddOnPage(this.bonusData, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: AppLocalizations.of(context).addOns,
            ),
            flexibleSpaceCaption:
                AppLocalizations.of(context).addOnPageSubtitle,
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (delegateBuildContext, index) {
                  final bonus = bonusData.getAddOnBonuses()[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: AddOnViewSection(
                      sectionName: bonus.type == 'ADD_ON_BF_2023'
                          ? "Black friday 2023"
                          : bonus.type.replaceAll('_', ' '),
                      bonus: bonus,
                    ),
                  );
                },
                childCount: bonusData.getAddOnBonuses().length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddOnViewSection extends StatelessWidget {
  final String sectionName;
  final Bonus bonus;

  const AddOnViewSection({
    super.key,
    required this.sectionName,
    required this.bonus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textStyle = getEnteTextTheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionName,
              style: textStyle.body.copyWith(
                color: colorScheme.textMuted,
              ),
            ),
            if (bonus.validTill != 0)
              Text(
                AppLocalizations.of(context).validTill(
                  endDate: DateFormat.yMMMd(
                    Localizations.localeOf(context).languageCode,
                  )
                      .format(
                        DateTime.fromMicrosecondsSinceEpoch(
                          bonus.validTill,
                        ),
                      )
                      .toString(),
                ),
                style: textStyle.body.copyWith(
                  color: colorScheme.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: convertBytesToReadableFormat(bonus.storage).toString(),
                style: textStyle.h3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
