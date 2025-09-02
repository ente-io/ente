import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/storage_bonus/bonus.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/payment/add_on_page.dart";
import "package:photos/utils/navigation_util.dart";

class ViewAddOnButton extends StatelessWidget {
  final BonusData? bonusData;

  const ViewAddOnButton(this.bonusData, {super.key});

  @override
  Widget build(BuildContext context) {
    if (bonusData?.getAddOnBonuses().isEmpty ?? true) {
      return const SizedBox.shrink();
    }
    final EnteColorScheme colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      child: MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: AppLocalizations.of(context).viewAddOnButton,
        ),
        menuItemColor: colorScheme.fillFaint,
        trailingWidget: Icon(
          Icons.chevron_right_outlined,
          color: colorScheme.strokeBase,
        ),
        singleBorderRadius: 4,
        alignCaptionedTextToLeft: true,
        onTap: () async {
          await routeToPage(context, AddOnPage(bonusData!));
        },
      ),
    );
  }
}
