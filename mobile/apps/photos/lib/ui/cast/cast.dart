import "package:ente_components/ente_components.dart";
import "package:flutter/widgets.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/cast/pair_with_auto.dart";
import "package:photos/ui/cast/pair_with_code.dart";
import "package:photos/ui/settings/cast/cast_settings_page.dart";

Future<void> showCastSheet(BuildContext context, Collection collection) async {
  final l10n = AppLocalizations.of(context);
  final textStyle = getEnteTextTheme(context);
  await castService.closeActiveCasts();
  return showBottomSheetComponent(
    context: context,
    builder: (_) => BottomSheetComponent(
      title: l10n.castAlbum,
      actions: [
        Text(l10n.pairWithAutoDesc, style: textStyle.smallMuted),
        ButtonComponent(
          label: l10n.autoPair,
          variant: .secondary,
          leading: const HugeIcon(icon: HugeIcons.strokeRoundedTvSmart),
          shouldSurfaceExecutionStates: false,
          onTap: () async {
            Navigator.of(context).pop();
            await showPairWithAutoSheet(context, collection);
          },
        ),
        Text(l10n.pairWithCodeDesc, style: textStyle.smallMuted),
        ButtonComponent(
          label: l10n.pairUsingCode,
          variant: .secondary,
          leading: const HugeIcon(icon: HugeIcons.strokeRoundedTv02),
          shouldSurfaceExecutionStates: false,
          onTap: () async {
            Navigator.of(context).pop();
            await showPairWithCodeSheet(context, collection);
          },
        ),
        const CastSessionsList(showTitle: true, fallback: SizedBox.shrink()),
      ],
    ),
  );
}
